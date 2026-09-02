import Foundation

struct Verification: Sendable {
  private let scriptPath: String
  private let bash: Bash

  init(workingDirectory: String) {
    self.scriptPath = "\(workingDirectory)/.agent/verify.sh"
    self.bash = Bash(workingDirectory: workingDirectory)
  }

  func failure() async throws -> String? {
    guard FileManager.default.fileExists(atPath: scriptPath) else {
      return nil
    }

    let result = try await bash.run("/bin/bash .agent/verify.sh")
    return result.exitCode == 0 ? nil : result.output
  }
}
