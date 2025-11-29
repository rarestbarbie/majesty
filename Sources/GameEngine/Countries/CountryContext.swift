import GameIDs
import GameState

struct CountryContext: RuntimeContext {
    let type: _NoMetadata
    var state: Country

    init(type: _NoMetadata, state: Country) {
        self.type = type
        self.state = state
    }
}
extension CountryContext {
    mutating func advance(turn: inout Turn, context: GameContext) throws {
    }
}
