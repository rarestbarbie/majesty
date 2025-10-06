import GameRules
import GameState
import JavaScriptInterop
import JavaScriptKit

struct CountryContext {
    let properties: CountryProperties

    init(type _: Metadata, state: Country) {
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
        map _: borrowing GameMap,
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
    mutating func advance(map: inout GameMap, context: GameContext) throws {}
}
extension CountryContext: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case state
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.state] = self.state
    }
}
