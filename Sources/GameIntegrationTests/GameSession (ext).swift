import GameEngine
import JavaScriptKit

extension GameSession {
    static func reload() throws -> Self {
        try .init(
            save: try .load(from: JSObject.global["start"]),
            rules: try .load(from: JSObject.global["rules"]),
            terrain: try .load(from: JSObject.global["terrain"]),
        )
    }
}
