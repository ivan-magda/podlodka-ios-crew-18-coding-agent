import Foundation
import OpenAI

struct Bash: Sendable {
  private let workingDirectory: URL

  init(workingDirectory: String) {
    self.workingDirectory = URL(fileURLWithPath: workingDirectory)
  }

  func execute(_ arguments: String) async throws -> String {
    let input = try JSONDecoder().decode(
      BashInput.self,
      from: Data(arguments.utf8)
    )

    print("$ \(input.command)")

    let process = Process()
    let stdout = Pipe()
    let stderr = Pipe()

    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", input.command]
    process.currentDirectoryURL = workingDirectory
    process.standardOutput = stdout
    process.standardError = stderr

    var environment = ProcessInfo.processInfo.environment
    environment.removeValue(forKey: "PODLODKA_OPENAI_API_KEY")
    process.environment = environment

    try process.run()

    async let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
    async let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
    let (capturedStdout, capturedStderr) = await (stdoutData, stderrData)

    process.waitUntilExit()

    return [
      String(decoding: capturedStdout, as: UTF8.self),
      String(decoding: capturedStderr, as: UTF8.self),
      "Exit code: \(process.terminationStatus)"
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "\n")
  }

  static let definition = ChatQuery.ChatCompletionToolParam(
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
