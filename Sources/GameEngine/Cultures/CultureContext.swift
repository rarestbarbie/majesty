import GameRules
import GameState

struct CultureContext: RuntimeContext {
    let type: CultureMetadata
    var state: Culture

    init(type: CultureMetadata, state: Culture) {
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
