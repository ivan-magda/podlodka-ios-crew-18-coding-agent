import Foundation
import OpenAI

struct Skills {
  private let skills: [String: Skill]

  init(workingDirectory: String) {
    let directory = URL(fileURLWithPath: workingDirectory)
      .appendingPathComponent("skills", isDirectory: true)
    let entries = (try? FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil
    )) ?? []

    var skills: [String: Skill] = [:]

    for entry in entries {
      let file = entry.appendingPathComponent("SKILL.md")

      guard
        let text = try? String(contentsOf: file, encoding: .utf8),
        let skill = Self.parse(text)
      else {
        continue
      }

      skills[skill.name] = skill
    }

    self.skills = skills
  }

  var prompt: String {
    guard !skills.isEmpty else {
      return ""
    }

    return """


    Use load_skill to load specialized instructions when they are relevant.

    Available skills:
    \(catalog)
    """
  }

  var toolDefinitions: [ChatQuery.ChatCompletionToolParam] {
    skills.isEmpty ? [] : [Self.definition]
  }

  private var catalog: String {
    skills.values
      .sorted { $0.name < $1.name }
      .map { "- \($0.name): \($0.description)" }
      .joined(separator: "\n")
  }

  func load(_ arguments: String) throws -> String {
    let input = try JSONDecoder().decode(
      LoadSkillInput.self,
      from: Data(arguments.utf8)
    )

    guard let skill = skills[input.name] else {
      throw SkillError("Unknown skill: \(input.name)")
    }

    return """
    <skill name="\(skill.name)">
    \(skill.body)
    </skill>
    """
  }

  static let definition = ChatQuery.ChatCompletionToolParam(
    function: .init(
      name: "load_skill",
      description: "Load specialized instructions by skill name.",
      parameters: .init(
        .type(.object),
        .properties([
          "name": .init(
            .type(.string),
            .description("Name from the available skills catalog.")
          )
        ]),
        .required(["name"]),
        .additionalProperties(.boolean(false))
      )
    )
  )

  private static func parse(_ text: String) -> Skill? {
    let lines = text.components(separatedBy: "\n")

    guard
      lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---",
      let closingIndex = lines.dropFirst().firstIndex(where: {
        $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---"
      })
    else {
      return nil
    }

    var name: String?
    var description: String?

    for line in lines[1..<closingIndex] {
      let line = line.trimmingCharacters(in: .whitespaces)

      if line.hasPrefix("name:") {
        name = String(line.dropFirst("name:".count))
          .trimmingCharacters(in: .whitespaces)
      } else if line.hasPrefix("description:") {
        description = String(line.dropFirst("description:".count))
          .trimmingCharacters(in: .whitespaces)
      }
    }

    guard
      let name,
      !name.isEmpty,
      let description,
      !description.isEmpty
    else {
      return nil
    }

    let body = lines
      .dropFirst(closingIndex + 1)
      .joined(separator: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    return Skill(name: name, description: description, body: body)
  }
}

private struct Skill {
  let name: String
  let description: String
  let body: String
}

private struct LoadSkillInput: Decodable {
  let name: String
}

private struct SkillError: LocalizedError {
  let message: String

  init(_ message: String) {
    self.message = message
  }

  var errorDescription: String? {
    message
  }
}
