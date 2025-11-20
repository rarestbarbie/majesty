import GameEconomy
import GameIDs
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct ProductionReport {
    private var selection: PersistentSelection<
        Filter,
        InventoryBreakdown<FactoryDetailsTab>.Focus
    >

    private var filters: ([FilterLabel], [Never])
    private var factories: [FactoryTableEntry]
    private var factory: FactoryDetails?

    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))

        self.filters = ([], [])
        self.factories = []
        self.factory = nil
    }
}
extension ProductionReport: PersistentReport {
    mutating func select(request: ProductionReportRequest) {
        self.selection.select(request.subject, filter: request.filter)
        self.selection.tab = request.details
        self.selection.needs = request.detailsTier
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        let country: CountryProperties = snapshot.player

        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = snapshot.factories.reduce(into: ([:], nil)) {
            let tile: Address = $1.state.tile
            if case country.id? = $1.region?.governedBy.id {
                {
                    $0 = $0 ?? snapshot.planets[tile].map { .location($0.name ?? "?", tile) }
                } (&$0.locations[tile])
            }
        }
        let filters: (
            location: [FilterLabel],
            Never?
        ) = (
            location: filterable.locations.values.sorted(),
            nil
        )

        self.selection.rebuild(
            filtering: snapshot.factories,
            entries: &self.factories,
            details: &self.factory,
            default: filters.location.first?.id ?? .all
        ) {
            guard case country.id? = $0.region?.governedBy.id else {
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
                type: $0.type.title,
                size: $0.state.size,
                liquidationProgress: liquidationProgress,
                yesterday: $0.state.y,
                today: $0.state.z,
                workers: $0.workers.map(FactoryWorkers.init(aggregate:)),
                clerks: $0.clerks.map(FactoryWorkers.init(aggregate:))
            )
        } update: {
            $0.update(to: $2, from: snapshot) ;
        }

        self.filters.0 = [.all] + filters.location
    }
}
extension ProductionReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case factories
        case factory

        case filter
        case filterlist
        case filterlists
    }
}
extension ProductionReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Production
        js[.factories] = self.factories
        js[.factory] = self.factory

        js[.filter] = self.selection.filter

        switch self.selection.filter {
        case nil: break
        case .all?: js[.filterlist] = 0
        case .location?: js[.filterlist] = 0
        }

        js[.filterlists] = [self.filters.0]
    }
}
