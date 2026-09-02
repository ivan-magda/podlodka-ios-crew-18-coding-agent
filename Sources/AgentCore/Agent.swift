import Foundation
import OpenAI

public final class Agent {
  private let client: OpenAI
  private let model: String
  private let bash: Bash
  private var messages: [ChatQuery.ChatCompletionMessageParam]

  public init(
    client: OpenAI,
    model: String,
    workingDirectory: String
  ) {
    self.client = client
    self.model = model
    self.bash = Bash(workingDirectory: URL(fileURLWithPath: workingDirectory))
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
        tools: [Self.bashTool]
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
        let output = try await executeTool(toolCall)
        messages.append(.tool(.init(
          content: .textContent(output),
          toolCallId: toolCall.id
        )))
      }
    }
  }

  private func executeTool(
    _ toolCall: ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam
  ) async throws -> String {
    precondition(toolCall.function.name == "bash")

    let input = try JSONDecoder().decode(
      BashInput.self,
      from: Data(toolCall.function.arguments.utf8)
    )

    print("$ \(input.command)")

    let output = try await bash.run(input.command)
    print(output)

    return output
  }

  private static func systemPrompt(_ workingDirectory: String) -> String {
    """
    You are a coding agent working in \(workingDirectory).
    Use Bash to inspect and modify the project, run commands, and complete the user's task.
    Check each command result before deciding what to do next.
    """
  }

  private static let bashTool = ChatQuery.ChatCompletionToolParam(
    function: .init(
      name: "bash",
      description: "Run a Bash command and return its output and exit code.",
      parameters: .init(
        .type(.object),
        .properties([
          "command": .init(
            .type(.string),
            .description("The Bash command to run.")
          )
        ]),
        .required(["command"]),
        .additionalProperties(.boolean(false))
      )
    )
  )
}

private struct BashInput: Decodable {
  let command: String
}
