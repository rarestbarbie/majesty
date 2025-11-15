import GameIDs
import GameRules
import GameState

struct CountryContext {
    let type: _NoMetadata
    let properties: CountryProperties

    init(type: _NoMetadata, state: Country) {
        self.type = type
        self.properties = .init(intrinsic: state)
    }
}
extension CountryContext: RuntimeContext {
    var state: Country {
        _read   { yield  self.properties.intrinsic }
        _modify { yield &self.properties.intrinsic }
    }
}
extension CountryContext {
    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: GameContext.TerritoryPass
    ) throws {
        self.properties.update(rules: context.rules)
    }
}
extension CountryContext {
    mutating func advance(turn: inout Turn, context: GameContext) throws {}
}
