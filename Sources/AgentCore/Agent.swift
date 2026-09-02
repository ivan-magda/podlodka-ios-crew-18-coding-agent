import OpenAI

public final class Agent {
  private static let toolOutputPreviewLength = 200

  private let client: OpenAI
  private let model: String
  private let bash: Bash
  private let fileTools: FileTools
  private var messages: [ChatQuery.ChatCompletionMessageParam]

  public init(
    client: OpenAI,
    model: String,
    workingDirectory: String
  ) {
    self.client = client
    self.model = model
    self.bash = Bash(workingDirectory: workingDirectory)
    self.fileTools = FileTools(workingDirectory: workingDirectory)
    self.messages = [
      .system(.init(content: .textContent(Self.systemPrompt(workingDirectory))))
    ]
  }

  public func run(_ prompt: String) async throws -> String {
    messages.append(.user(.init(content: .string(prompt))))

    while true {
      let result = try await client.chats(query: ChatQuery(
        messages: messages,
        model: model,
        tools: [Bash.definition] + FileTools.definitions
      ))

      let response = result.choices[0].message
      let toolCalls = response.toolCalls ?? []

      messages.append(.assistant(.init(
        content: response.content.map { .textContent($0) },
        reasoningContent: response.reasoning,
        toolCalls: toolCalls
      )))

      if let text = response.content, !text.isEmpty {
        print(text)
      }

      guard !toolCalls.isEmpty else {
        return response.content ?? ""
      }

      for toolCall in toolCalls {
        let output = await executeTool(toolCall)
        messages.append(.tool(.init(
          content: .textContent(output),
          toolCallId: toolCall.id
        )))
      }
    }
  }

  private func executeTool(
    _ toolCall: ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam
  ) async -> String {
    let handlers: [String: (String) async throws -> String] = [
      "bash": bash.execute,
      "read_file": fileTools.readFile,
      "write_file": fileTools.writeFile,
      "edit_file": fileTools.editFile
    ]

    let name = toolCall.function.name
    print("→ \(name)")

    let output: String
    if let handler = handlers[name] {
      do {
        output = try await handler(toolCall.function.arguments)
      } catch {
        output = "Error: \(error.localizedDescription)"
      }
    } else {
      output = "Error: Unknown tool: \(name)"
    }

    printToolOutput(output)

    return output
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
    Check each tool result before proceeding.
    """
  }
}
