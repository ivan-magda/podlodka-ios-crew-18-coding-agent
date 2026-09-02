import Foundation
import OpenAI

struct FileTools {
  private static let maximumReadCharacters = 50_000

  private let root: URL

  init(workingDirectory: String) {
    self.root = URL(
      fileURLWithPath: workingDirectory,
      isDirectory: true
    )
    .standardizedFileURL
    .resolvingSymlinksInPath()
  }

  func readFile(_ arguments: String) throws -> String {
    let input = try decode(FilePathInput.self, from: arguments)
    let file = try resolve(input.path)
    let content = try String(contentsOf: file, encoding: .utf8)

    guard content.count > Self.maximumReadCharacters else {
      return content
    }

    return String(content.prefix(Self.maximumReadCharacters)) + "\n... output truncated"
  }

  func writeFile(_ arguments: String) throws -> String {
    let input = try decode(WriteFileInput.self, from: arguments)
    let file = try resolve(input.path)

    try FileManager.default.createDirectory(
      at: file.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try input.content.write(to: file, atomically: true, encoding: .utf8)

    return "Wrote \(input.content.utf8.count) bytes to \(input.path)"
  }

  func editFile(_ arguments: String) throws -> String {
    let input = try decode(EditFileInput.self, from: arguments)
    let file = try resolve(input.path)
    let content = try String(contentsOf: file, encoding: .utf8)
    let parts = content.components(separatedBy: input.oldText)

    guard !input.oldText.isEmpty, parts.count == 2 else {
      throw ToolError("old_text must appear exactly once in \(input.path)")
    }

    let updatedContent = parts.joined(separator: input.newText)
    try updatedContent.write(to: file, atomically: true, encoding: .utf8)

    return "Edited \(input.path)"
  }

  private func resolve(_ path: String) throws -> URL {
    guard !path.hasPrefix("/") else {
      throw ToolError("Only relative paths are allowed: \(path)")
    }

    let file = root
      .appendingPathComponent(path)
      .standardizedFileURL

    guard file.path == root.path || file.path.hasPrefix(root.path + "/") else {
      throw ToolError("Path escapes working directory: \(path)")
    }

    var current = root
    for component in file.pathComponents.dropFirst(root.pathComponents.count) {
      current = current.appendingPathComponent(component)

      if (try? FileManager.default.destinationOfSymbolicLink(atPath: current.path)) != nil {
        throw ToolError("Symbolic links are not allowed: \(path)")
      }
    }

    return file
  }

  private func decode<Input: Decodable>(
    _ type: Input.Type,
    from arguments: String
  ) throws -> Input {
    try JSONDecoder().decode(Input.self, from: Data(arguments.utf8))
  }

  static let definitions = [
    tool(
      name: "read_file",
      description: "Read a UTF-8 file in the working directory.",
      properties: [
        "path": string("Relative file path.")
      ],
      required: ["path"]
    ),
    tool(
      name: "write_file",
      description: "Create or overwrite a UTF-8 file in the working directory.",
      properties: [
        "path": string("Relative file path."),
        "content": string("Complete file content.")
      ],
      required: ["path", "content"]
    ),
    tool(
      name: "edit_file",
      description: "Replace one exact text occurrence in a UTF-8 file.",
      properties: [
        "path": string("Relative file path."),
        "old_text": string("Exact text that must appear once."),
        "new_text": string("Replacement text.")
      ],
      required: ["path", "old_text", "new_text"]
    )
  ]

  private static func tool(
    name: String,
    description: String,
    properties: [String: JSONSchema],
    required: [String]
  ) -> ChatQuery.ChatCompletionToolParam {
    ChatQuery.ChatCompletionToolParam(
      function: .init(
        name: name,
        description: description,
        parameters: .init(
          .type(.object),
          .properties(properties),
          .required(required),
          .additionalProperties(.boolean(false))
        )
      )
    )
  }

  private static func string(_ description: String) -> JSONSchema {
    .init(
      .type(.string),
      .description(description)
    )
  }
}

private struct FilePathInput: Decodable {
  let path: String
}

private struct WriteFileInput: Decodable {
  let path: String
  let content: String
}

private struct EditFileInput: Decodable {
  let path: String
  let oldText: String
  let newText: String

  enum CodingKeys: String, CodingKey {
    case path
    case oldText = "old_text"
    case newText = "new_text"
  }
}

private struct ToolError: LocalizedError {
  let message: String

  init(_ message: String) {
    self.message = message
  }

  var errorDescription: String? {
    message
  }
}
