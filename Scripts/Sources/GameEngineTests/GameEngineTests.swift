@_spi(testable) import GameEngine

import ArgumentParser
import SystemIO
import System_ArgumentParser
import GameRules

struct GameEngineTests: Sendable {
    @Option(
        name: [.customLong("resources")],
        help: "Specify the path to the test configuration file"
    )
    var resources: FilePath.Directory = "Public"
}
@main extension GameEngineTests: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "game-engine-tests",
            abstract: "Run Game Engine tests"
        )
    }
    func run() async throws {
        let resources: GameResources = try .init(resources: self.resources)
        let state: GameSession.State = try resources.load()
        let hash: Int = state.rules.hash
        print("Hash of the game rules: \(String.init(UInt.init(bitPattern: hash), radix: 16))")
    }
}
