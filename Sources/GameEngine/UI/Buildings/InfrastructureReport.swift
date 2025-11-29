import GameEconomy
import GameIDs
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct InfrastructureReport {
    private var selection: PersistentSelection<
        Filter,
        InventoryBreakdown<BuildingDetailsTab>.Focus
    >

    private var filters: ([FilterLabel], [Never])
    private var buildings: [BuildingTableEntry]
    private var building: BuildingDetails?

    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))

        self.filters = ([], [])
        self.buildings = []
        self.building = nil
    }
}
extension InfrastructureReport: PersistentReport {
    mutating func select(request: InfrastructureReportRequest) {
        self.selection.select(request.subject, filter: request.filter)
        self.selection.tab = request.details
        self.selection.needs = request.detailsTier
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        let country: CountryID = snapshot.player

        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = snapshot.buildings.reduce(into: ([:], nil)) {
            let tile: Address = $1.state.tile
            if case country? = $1.region?.governedBy {
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
            filtering: snapshot.buildings,
            entries: &self.buildings,
            details: &self.building,
            default: filters.location.first?.id ?? .all
        ) {
            guard case country? = $0.region?.governedBy else {
                return nil
            }
            guard
            let planet: PlanetContext = snapshot.planets[$0.state.tile.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[$0.state.tile.tile] else {
                return nil
            }

            return .init(
                id: $0.state.id,
                location: tile.name ?? planet.state.name,
                type: $0.type.title,
                state: $0.state,
            )
        } update: {
            $0.update(to: $2, from: snapshot) ;
        }

        self.filters.0 = [.all] + filters.location
    }
}
extension InfrastructureReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case buildings
        case building

        case filter
        case filterlist
        case filterlists
    }
}
extension InfrastructureReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Infrastructure
        js[.buildings] = self.buildings
        js[.building] = self.building

        js[.filter] = self.selection.filter

        switch self.selection.filter {
        case nil: break
        case .all?: js[.filterlist] = 0
        case .location?: js[.filterlist] = 0
        }

        js[.filterlists] = [self.filters.0]
    }
}
