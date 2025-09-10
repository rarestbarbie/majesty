import GameEconomy
import GameState
import GameTerrain
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
        subject: FactoryID?,
        details: FactoryDetailsTab?,
        filter: Never?
    ) {
        if  let subject: FactoryID {
            self.factory = .init(id: subject, open: self.factory?.open ?? .Inventory)
        }
        if  let details: FactoryDetailsTab {
            self.factory?.open = details
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.factories.removeAll()

        guard
        let country: CountryContext = snapshot.countries[snapshot.player] else {
            return
        }

        let include: Set<PlanetID> = .init(country.state.territory)
        for factory: FactoryContext in snapshot.factories where include.contains(
            factory.state.on.planet
        ) {
            guard
            let planet: PlanetContext = snapshot.planets[factory.state.on.planet],
            let tile: PlanetTile = planet.cells[factory.state.on.tile]?.tile else {
                continue
            }

            let valuation: Int64 = factory.state.cash.liq +
                factory.state.cash.v +
                factory.state.cash.b +
                factory.state.cash.r +
                factory.state.cash.s +
                factory.state.cash.c +
                factory.state.cash.w +
                factory.state.cash.i +
                factory.state.today.vi +
                factory.state.today.vv

            self.factories.append(
                .init(
                    id: factory.state.id,
                    location: tile.name ?? planet.state.name,
                    type: factory.type.name,
                    size: factory.state.size,
                    valuation: valuation,
                    yesterday: factory.state.yesterday,
                    today: factory.state.today,
                    workers: .init(aggregate: factory.workers),
                    clerks: factory.clerks.map(FactoryWorkers.init(aggregate:))
                )
            )
        }

        self.factory?.update(from: snapshot)
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
