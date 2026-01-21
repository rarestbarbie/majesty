 @_spi(testable) import GameEngine
import GameRules
import GameTerrain
import JavaScriptInterop
import JSON
import SystemIO

struct GameResources {
    let terrain: JSON.Node
    let rules: JSON.Node
    let start: JSON.Node
}
extension GameResources {
    init(resources: FilePath.Directory) throws {
        let terrain: FilePath = resources / "terrain.json"
        let rules: FilePath = resources / "rules.json"
        let start: FilePath = resources / "start.json"
        self.init(
            terrain: try .init(parsing: .init(utf8: try terrain.read()[...])),
            rules: try .init(parsing: .init(utf8: try rules.read()[...])),
            start: try .init(parsing: .init(utf8: try start.read()[...])),
        )
    }
}
extension GameResources {
    func load() throws -> GameSession.State {
        let terrain: TerrainMap = try .load(from: try JSValue.json(self.terrain))
        let rules: GameRules = try .load(from: try JSValue.json(self.rules))
        let start: GameStart = try .load(from: try JSValue.json(self.start))
        return try .load(start: start, rules: rules, map: terrain)
    }
}
