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
    mutating func compute(
        world _: borrowing GameWorld,
        context: GameContext.TerritoryPass
    ) throws {
        self.properties.technology { (
                factories: inout FactoryModifiers
            ) in

            for id: Technology in self.state.researched {
                guard
                let technology: TechnologyMetadata = context.rules.technologies[id] else {
                    continue
                }
                for effect: Effect in technology.effects {
                    switch effect {
                    case .factoryProductivity(let effects):
                        factories.productivity.base.stack(with: effects)
                    }
                }
            }
        }
    }
}
extension CountryContext {
    mutating func advance(turn: inout Turn, context: GameContext) throws {}
}
