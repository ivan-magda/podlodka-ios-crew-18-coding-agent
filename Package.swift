// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "PodlodkaCodingAgent",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "agent", targets: ["AgentCLI"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/MacPaw/OpenAI.git",
      exact: "0.5.1"
    )
  ],
  targets: [
    .target(
      name: "AgentCore",
      dependencies: [
        .product(name: "OpenAI", package: "OpenAI")
      ]
    ),
    .executableTarget(
      name: "AgentCLI",
      dependencies: [
        "AgentCore",
        .product(name: "OpenAI", package: "OpenAI")
      ]
    )
  ]
)
