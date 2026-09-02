import Foundation
import OpenAI

struct SubagentTool {
  private static let maximumResultCharacters = 2_000
  private static let truncationMarker = "\n… subagent result truncated"

  static func task(from arguments: String) throws -> String {
    let input = try JSONDecoder().decode(
      SubagentInput.self,
      from: Data(arguments.utf8)
    )

    return input.task
  }

  static func format(_ result: String) -> String {
    guard result.count > maximumResultCharacters else {
      return result
    }

    let prefixLength = maximumResultCharacters - truncationMarker.count
    return String(result.prefix(prefixLength)) + truncationMarker
  }

  static let definition = ChatQuery.ChatCompletionToolParam(
    function: .init(
      name: "subagent",
      description: "Delegate a task to a general-purpose agent with a fresh context.",
      parameters: .init(
        .type(.object),
        .properties([
          "task": .init(
            .type(.string),
            .description("Self-contained task with only the context the subagent needs.")
          )
        ]),
        .required(["task"]),
        .additionalProperties(.boolean(false))
      )
    )
  )
}

private struct SubagentInput: Decodable {
  let task: String
}
