@_spi(testable) import GameEngine

import ArgumentParser
import SystemIO
import System_ArgumentParser
import GameRules
import GameIDs
import JSON
import JavaScriptInterop

struct GameEngineTests: Sendable {
    @Option(
        name: [.customLong("resources")],
        help: "Specify the path to the test configuration file"
    ) var resources: FilePath.Directory = "Public"
    @Option(
        name: [.customLong("output")],
        help: "Specify the output directory for test results"
    ) var output: FilePath.Directory = ".games"
    @Option(
        name: [.customLong("target")],
        help: "Target date to run the simulation until (in YYYY-MM-DD format)"
    ) var target: GameDate = .gregorian(year: 2425, month: 2, day: 1)
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
        var state: GameSession.State = try resources.load()
        try state.run(until: self.target)

        let json: JSON = .encode(JSObject.new(encoding: state.save))

        try self.output.create()
        let output: FilePath = self.output / "\(self.target).json"
        try output.overwrite(with: json.utf8[...])

        print("output written to \(output)")
    }
}
