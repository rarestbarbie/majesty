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
    mutating func compute(
        map _: borrowing GameMap,
        context: GameContext.TerritoryPass
    ) throws {
    }

    mutating func advance(map: inout GameMap, context: GameContext) throws {}
}
