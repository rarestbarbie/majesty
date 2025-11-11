import GameEngine
import GameRules
import GameTerrain
import JavaScriptKit

extension GameSession {
    static func reload() throws -> Self {
        let rules: GameRulesDescription = try .load(from: JSObject.global["rules"])
        let terrain: TerrainMap = try .load(from: JSObject.global["terrain"])
        let save: GameSave = try .load(from: JSObject.global["start"])
        return try .load(save, rules: rules, map: terrain)
    }
}
