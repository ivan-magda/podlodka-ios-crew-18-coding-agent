import Foundation

struct Bash: Sendable {
  let workingDirectory: URL

  func run(_ command: String) async throws -> String {
    let process = Process()
    let stdout = Pipe()
    let stderr = Pipe()

    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c", command]
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
}
