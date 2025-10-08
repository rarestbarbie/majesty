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
            let planet: PlanetContext = snapshot.planets[factory.state.tile.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[factory.state.tile.tile] else {
                continue
            }

            let liquidationProgress: Double? = factory.state.liquidation.map {
                $0.burning == 0 ? 1 : Double(
                    $0.burning - factory.equity.shareCount
                ) / Double($0.burning)
            }

            self.factories.append(
                .init(
                    id: factory.state.id,
                    location: tile.name ?? planet.state.name,
                    type: factory.type.name,
                    size: factory.state.size,
                    liquidationProgress: liquidationProgress,
                    yesterday: factory.state.yesterday,
                    today: factory.state.today,
                    workers: factory.workers.map(FactoryWorkers.init(aggregate:)),
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
