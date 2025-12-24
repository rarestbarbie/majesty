import GameEconomy
import GameIDs
import GameState
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct InfrastructureReport {
    private var selection: PersistentSelection<
        Filters,
        InventoryBreakdown<BuildingDetailsTab>.Focus
    >

    private var filters: ([FilterLabel], [Never])
    private var entries: [BuildingTableEntry]
    private var details: BuildingDetails?

    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))

        self.filters = ([], [])
        self.entries = []
        self.details = nil
    }
}
extension InfrastructureReport: PersistentReport {
    mutating func select(request: InfrastructureReportRequest) {
        self.selection.select(request.subject, filter: request.filter)
        self.selection.tab = request.details
        self.selection.needs = request.detailsTier
    }
}
extension InfrastructureReport {
    private var sort: Sort {
        .init()
    }

    mutating func update(from cache: borrowing GameUI.Cache) {
        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = cache.buildings.values.reduce(into: ([:], nil)) {
            $0.locations[$1.state.tile] = .location($1.region.name, $1.state.tile)
        }
        let filters: (
            location: [FilterLabel],
            Never?
        ) = (
            location: filterable.locations.values.sorted(),
            nil
        )

        /// TODO: return a better default here
        let defaultTile: Address? = filters.location.first.map {
            switch $0 {
            case .location(_, let address): address
            }
        }

        self.selection.rebuild(
            filtering: cache.buildings,
            entries: &self.entries,
            details: &self.details,
            default: .init(location: defaultTile),
            sort: self.sort.ascending(_:_:)
        ) {
            let entry: BuildingTableEntry = .init(
                id: $0.state.id,
                location: $0.region.name,
                type: $0.type.title,
                state: $0.state,
            )

            return entry
        } update: {
            $0.update(to: $2, cache: cache)
        }

        self.filters.0 = filters.location
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
        js[.buildings] = self.entries
        js[.building] = self.details

        // currently there is only one filterlist in the sidebar
        js[.filter] = self.selection.filters.location.map(Filter.location(_:))
        js[.filterlist] = 0
        js[.filterlists] = [self.filters.0]
    }
}
