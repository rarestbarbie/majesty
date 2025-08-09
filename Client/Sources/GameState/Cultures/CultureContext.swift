import GameEngine
import JavaScriptKit
import JavaScriptInterop

struct CultureContext {
    var state: Culture

    init(type _: Metadata, state: Culture) {
        self.state = state
    }
}
extension CultureContext: RuntimeContext {
    mutating func compute(in context: GameState) throws {
    }

    mutating func advance(in context: GameContext, on map: inout GameMap) throws {
    }
}
