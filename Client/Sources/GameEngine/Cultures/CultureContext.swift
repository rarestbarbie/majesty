import GameState

struct CultureContext: RuntimeContext {
    var state: Culture

    init(type _: Metadata, state: Culture) {
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
