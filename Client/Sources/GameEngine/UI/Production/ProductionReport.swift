import GameEconomy
import GameIDs
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct ProductionReport {
    private var selection: PersistentSelection<Filter, FactoryDetailsTab>
    private var factories: [FactoryTableEntry]
    private var factory: FactoryDetails?

    init() {
        self.selection = .init(defaultTab: .Inventory)
        self.factories = []
        self.factory = nil
    }
}
extension ProductionReport: PersistentReport {
    mutating func select(
        subject: FactoryID?,
        details: FactoryDetailsTab?,
        filter: Filter?
    ) {
        self.selection.select(subject, detailsTab: details)
        if  let filter: Filter {
            self.selection.filter(filter)
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.factories.removeAll()

        let country: CountryProperties = snapshot.player
        self.selection.rebuild(
            filtering: snapshot.factories,
            entries: &self.factories,
            details: &self.factory,
            default: .all
        ) {
            guard case country.id? = $0.governedBy?.id else {
                return nil
            }
            guard
            let planet: PlanetContext = snapshot.planets[$0.state.tile.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[$0.state.tile.tile] else {
                return nil
            }

            let equity: Equity<LEI>.Statistics = $0.equity
            let liquidationProgress: Double? = $0.state.liquidation.map {
                $0.burning == 0 ? 1 : Double(
                    $0.burning - equity.shareCount
                ) / Double($0.burning)
            }

            return .init(
                id: $0.state.id,
                location: tile.name ?? planet.state.name,
                type: $0.type.name,
                size: $0.state.size,
                liquidationProgress: liquidationProgress,
                yesterday: $0.state.yesterday,
                today: $0.state.today,
                workers: $0.workers.map(FactoryWorkers.init(aggregate:)),
                clerks: $0.clerks.map(FactoryWorkers.init(aggregate:))
            )
        } update: {
            $0.update(to: $2, from: snapshot) ;
        }
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
