import GameRules
import GameState
import JavaScriptInterop
import JavaScriptKit

struct CountryContext {
    var state: Country
    var factories: FactoryModifiers

    init(type _: Metadata, state: Country) {
        self.state = state
        self.factories = .init()
    }
}
extension CountryContext {
    private mutating func apply(effects: Effect) {
        switch effects {
        case .factoryProductivity(let effects):
            self.factories.productivity.base.stack(with: effects)
        }
    }
}
extension CountryContext: RuntimeContext {
    mutating func compute(in context: GameContext.TerritoryPass) throws {
        self.factories = .init()
        for id: Technology in self.state.researched {
            guard let technology: TechnologyMetadata = context.rules.technologies[id] else {
                continue
            }
            for effect: Effect in technology.effects {
                self.apply(effects: effect)
            }
        }
    }
    mutating func advance(in context: GameContext, on map: inout GameMap) throws {
    }
}
extension CountryContext: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case state
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.state] = self.state
    }
}
