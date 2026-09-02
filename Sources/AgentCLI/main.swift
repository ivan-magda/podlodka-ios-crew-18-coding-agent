import AgentCore
import Foundation
import OpenAI

@main
enum AgentCLI {
  static func main() async throws {
    let environment = ProcessInfo.processInfo.environment

    guard let apiKey = environment["PODLODKA_OPENAI_API_KEY"] else {
      print("Set PODLODKA_OPENAI_API_KEY before running the agent.")
      return
    }

    guard let model = environment["PODLODKA_OPENAI_MODEL"] else {
      print("Set PODLODKA_OPENAI_MODEL before running the agent.")
      return
    }

    let baseURLString = environment["PODLODKA_OPENAI_BASE_URL"] ?? "https://api.openai.com/v1"
    guard
      let baseURL = URL(string: baseURLString),
      let scheme = baseURL.scheme,
      let host = baseURL.host
    else {
      print("PODLODKA_OPENAI_BASE_URL must be a full URL, such as https://api.openai.com/v1.")
      return
    }

    let configuration = OpenAI.Configuration(
      token: apiKey,
      host: host,
      port: baseURL.port ?? (scheme == "http" ? 80 : 443),
      scheme: scheme,
      basePath: baseURL.path,
      parsingOptions: .relaxed
    )

    let workingDirectory = FileManager.default.currentDirectoryPath
    let agent = Agent(
      client: OpenAI(configuration: configuration),
      model: model,
      workingDirectory: workingDirectory
    )

    print("Coding agent in \(workingDirectory). Type exit to quit.")

    while true {
      print("> ", terminator: "")

      guard let input = readLine() else {
        break
      }

      if input == "exit" {
        break
      }

      if input.isEmpty {
        continue
      }

      do {
        _ = try await agent.run(input)
      } catch {
        print("Error: \(error)")
      }
    }
  }
}
