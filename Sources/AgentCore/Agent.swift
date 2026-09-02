import Foundation
import OpenAI

public final class Agent {
  private static let toolOutputPreviewLength = 200
  private static let todoReminderThreshold = 3
  private static let recentToolResultsToKeep = 5
  private static let maximumOldToolResultCharacters = 2_000
  private static let maximumContextCharacters = 100_000

  private let client: OpenAI
  private let model: String
  private let workingDirectory: String
  private let allowsSubagents: Bool
  private let bash: Bash
  private let fileTools: FileTools
  private let skills: Skills
  private let todo = Todo()
  private var messages: [ChatQuery.ChatCompletionMessageParam]

  public init(
    client: OpenAI,
    model: String,
    workingDirectory: String,
    allowsSubagents: Bool = true
  ) {
    let skills = Skills(workingDirectory: workingDirectory)

    self.client = client
    self.model = model
    self.workingDirectory = workingDirectory
    self.allowsSubagents = allowsSubagents
    self.bash = Bash(workingDirectory: workingDirectory)
    self.fileTools = FileTools(workingDirectory: workingDirectory)
    self.skills = skills
    self.messages = [
      .system(.init(content: .textContent(
        Self.systemPrompt(workingDirectory) + skills.prompt
      )))
    ]
  }

  public func run(_ prompt: String) async throws -> String {
    messages.append(.user(.init(content: .string(prompt))))
    var turnsWithoutTodo = 0

    while true {
      await autoCompactIfNeeded()

      let result = try await client.chats(query: ChatQuery(
        messages: messages,
        model: model,
        tools: availableTools
      ))

      let response = result.choices[0].message
      let toolCalls = response.toolCalls ?? []

      messages.append(.assistant(.init(
        content: response.content.map { .textContent($0) },
        reasoningContent: response.reasoning,
        toolCalls: toolCalls
      )))
      compactOldToolResults()

      if let text = response.content, !text.isEmpty {
        print(text)
      }

      guard !toolCalls.isEmpty else {
        return response.content ?? ""
      }

      var didUseTodo = false

      for toolCall in toolCalls {
        let output = await executeTool(toolCall)
        messages.append(.tool(.init(
          content: .textContent(output),
          toolCallId: toolCall.id
        )))

        if toolCall.function.name == "todo" {
          didUseTodo = true
        }
      }

      turnsWithoutTodo = didUseTodo ? 0 : turnsWithoutTodo + 1

      if turnsWithoutTodo >= Self.todoReminderThreshold, todo.hasOpenItems {
        let reminder = """
        Current todo:
        \(todo.render())

        Update your todo list.
        """
        print(reminder)
        messages.append(.user(.init(content: .string(reminder))))
      }
    }
  }

  private var availableTools: [ChatQuery.ChatCompletionToolParam] {
    var tools = [Bash.definition]
      + FileTools.definitions
      + [Todo.definition]
      + skills.toolDefinitions

    if allowsSubagents {
      tools.append(SubagentTool.definition)
    }

    return tools
  }

  private func executeTool(
    _ toolCall: ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam
  ) async -> String {
    let handlers: [String: (String) async throws -> String] = [
      "bash": bash.execute,
      "read_file": fileTools.readFile,
      "write_file": fileTools.writeFile,
      "edit_file": fileTools.editFile,
      "todo": todo.execute,
      "load_skill": skills.load,
      "subagent": executeSubagent
    ]

    let name = toolCall.function.name
    print("→ \(name)")

    let output: String
    if name == "subagent", !allowsSubagents {
      output = "Error: A subagent cannot start another subagent"
    } else if let handler = handlers[name] {
      do {
        output = try await handler(toolCall.function.arguments)
      } catch {
        output = "Error: \(error.localizedDescription)"
      }
    } else {
      output = "Error: Unknown tool: \(name)"
    }

    if name == "todo" {
      print(output)
    } else {
      printToolOutput(output)
    }

    return output
  }

  private func executeSubagent(_ arguments: String) async throws -> String {
    let task = try SubagentTool.task(from: arguments)
    let subagent = Agent(
      client: client,
      model: model,
      workingDirectory: workingDirectory,
      allowsSubagents: false
    )

    print("── subagent ──")
    defer { print("── main agent ──") }

    return SubagentTool.format(try await subagent.run(task))
  }

  private func compactOldToolResults() {
    let toolMessageIndices = messages.indices.filter {
      messages[$0].role == .tool
    }

    var compactedResults = 0

    for index in toolMessageIndices.dropLast(Self.recentToolResultsToKeep) {
      guard
        case .tool(let toolMessage) = messages[index],
        case .textContent(let output) = toolMessage.content,
        output.count > Self.maximumOldToolResultCharacters
      else {
        continue
      }

      messages[index] = .tool(.init(
        content: .textContent(
          "[Old tool result removed from active context. Inspect the source again if needed.]"
        ),
        toolCallId: toolMessage.toolCallId
      ))
      compactedResults += 1
    }

    if compactedResults > 0 {
      print("Context compacted: \(compactedResults) old tool results")
    }
  }

  private func autoCompactIfNeeded() async {
    do {
      let transcript = String(
        decoding: try JSONEncoder().encode(messages),
        as: UTF8.self
      )

      guard transcript.count > Self.maximumContextCharacters else {
        return
      }

      let prompt = """
      Summarize this coding-agent conversation so work can continue without the original messages.
      Preserve the user's request and constraints, completed work, current state, important file paths and decisions, \
      tool results and checks, unresolved errors, relevant loaded skills, and next steps.
      Return only the summary.

      \(transcript)
      """

      let result = try await client.chats(query: ChatQuery(
        messages: [.user(.init(content: .string(prompt)))],
        model: model
      ))
      let summary = result.choices[0].message.content ?? ""

      guard !summary.isEmpty else {
        return
      }

      messages = [
        messages[0],
        .user(.init(content: .string("""
        Previous conversation summary:
        \(summary)

        Current todo:
        \(todo.render())

        Continue the task from this state.
        """)))
      ]

      print("Context auto-compacted")
    } catch {
      print("Auto-compaction failed: \(error.localizedDescription)")
    }
  }

  private func printToolOutput(_ output: String) {
    let preview = String(output.prefix(Self.toolOutputPreviewLength))
    print(preview)

    if preview.count < output.count {
      print("… output truncated")
    }
  }

  private static func systemPrompt(_ workingDirectory: String) -> String {
    """
    You are a coding agent working in \(workingDirectory).
    Use tools to complete the user's task.
    Prefer read_file, write_file, and edit_file over bash for file operations.
    Use bash to run commands.
    Use todo for multi-step tasks and keep it current as you work.
    Check each tool result before proceeding.
    """
  }
}
