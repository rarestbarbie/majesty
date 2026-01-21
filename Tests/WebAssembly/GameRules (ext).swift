import GameEngine
import GameRules
import GameTerrain
import JavaScriptKit

extension GameRules {
    static func reload() throws -> Self {
        try .load(from: JSObject.global["rules"])
    }
}
