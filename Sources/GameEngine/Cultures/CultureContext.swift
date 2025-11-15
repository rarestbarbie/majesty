import GameState

struct CultureContext: RuntimeContext {
    let type: _NoMetadata
    var state: Culture

    init(type: _NoMetadata, state: Culture) {
        self.type = type
        self.state = state
    }
}
extension CultureContext {
    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: GameContext.TerritoryPass
    ) throws {
    }

    mutating func advance(turn: inout Turn, context: GameContext) throws {}
}
