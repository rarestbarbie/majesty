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

        for factory: FactoryContext in snapshot.factories {
            guard case country.state.id? = factory.governedBy?.id else {
                continue
            }
            guard
            let planet: PlanetContext = snapshot.planets[factory.state.on.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[factory.state.on.tile] else {
                continue
            }

            self.factories.append(
                .init(
                    id: factory.state.id,
                    location: tile.name ?? planet.state.name,
                    type: factory.type.name,
                    size: factory.state.size,
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
