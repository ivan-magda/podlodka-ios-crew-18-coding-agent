import Foundation
import OpenAI

final class Todo {
  private var items: [TodoItem] = []

  var hasOpenItems: Bool {
    items.contains { $0.status != .completed }
  }

  func execute(_ arguments: String) throws -> String {
    let input = try JSONDecoder().decode(
      TodoInput.self,
      from: Data(arguments.utf8)
    )

    guard input.items.filter({ $0.status == .inProgress }).count <= 1 else {
      throw TodoError("Only one todo item can be in_progress")
    }

    items = input.items
    return render()
  }

  func render() -> String {
    guard !items.isEmpty else {
      return "No todos."
    }

    return items
      .map { "\($0.status.marker) \($0.id): \($0.text)" }
      .joined(separator: "\n")
  }

  static let definition = ChatQuery.ChatCompletionToolParam(
    function: .init(
      name: "todo",
      description: "Replace the current todo list for a multi-step task.",
      parameters: .init(
        .type(.object),
        .properties([
          "items": .init(
            .type(.array),
            .items(.init(
              .type(.object),
              .properties([
                "id": string("Stable step identifier."),
                "text": string("Step description."),
                "status": .init(
                  .type(.string),
                  .enumValues(["pending", "in_progress", "completed"])
                )
              ]),
              .required(["id", "text", "status"]),
              .additionalProperties(.boolean(false))
            ))
          )
        ]),
        .required(["items"]),
        .additionalProperties(.boolean(false))
      )
    )
  )

  private static func string(_ description: String) -> JSONSchema {
    .init(
      .type(.string),
      .description(description)
    )
  }
}

private struct TodoInput: Decodable {
  let items: [TodoItem]
}

private struct TodoItem: Decodable {
  let id: String
  let text: String
  let status: TodoStatus
}

private enum TodoStatus: String, Decodable {
  case pending
  case inProgress = "in_progress"
  case completed

  var marker: String {
    switch self {
    case .pending: "[ ]"
    case .inProgress: "[>]"
    case .completed: "[x]"
    }
  }
}

private struct TodoError: LocalizedError {
  let message: String

  init(_ message: String) {
    self.message = message
  }

  var errorDescription: String? {
    message
  }
}
