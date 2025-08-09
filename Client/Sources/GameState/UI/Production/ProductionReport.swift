import GameEconomy
import GameEngine
import JavaScriptKit
import JavaScriptInterop

public struct ProductionReport {
    private var factories: [FactoryTableEntry]
    private var factory: FactoryDetails?

    init() {
        self.factories = []
        self.factory = nil
    }
}
extension ProductionReport: PersistentReport {
    mutating func select(
        subject: GameID<Factory>?,
        details: FactoryDetailsTab?,
        filter: Never?
    ) {
        if  let subject: GameID<Factory> {
            self.factory = .init(id: subject, open: self.factory?.open ?? .Inventory)
        }
        if  let details: FactoryDetailsTab {
            self.factory?.open = details
        }
    }

    mutating func update(on map: borrowing GameMap, in context: GameContext) {
        self.factories.removeAll()

        guard
        let country: CountryContext = context.countries[context.player] else {
            return
        }

        let include: Set<GameID<Planet>> = .init(country.state.territory)
        for factory: FactoryContext in context.factories where include.contains(
            factory.state.on
        ) {
            guard
            let location: Planet = context.state.planets[factory.state.on] else {
                continue
            }

            self.factories.append(.init(
                id: factory.state.id,
                location: location.name,
                type: factory.type.name,
                grow: factory.state.grow,
                size: factory.state.size,
                cash: factory.state.cash,
                yesterday: factory.state.yesterday,
                today: factory.state.today,
                workers: .init(
                    type: factory.type.workers.unit,
                    aggregate: factory.workers,
                ),
                clerks: .init(
                    type: factory.type.clerks.unit,
                    aggregate: factory.clerks,
                ),
            ))
        }

        self.factory?.update(in: context)
    }
}
extension ProductionReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case factories
        case factory
    }
}
extension ProductionReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Production
        js[.factories] = self.factories
        js[.factory] = self.factory
    }
}
