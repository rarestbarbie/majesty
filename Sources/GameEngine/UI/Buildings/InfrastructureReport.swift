import GameEconomy
import GameIDs
import GameState
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct InfrastructureReport {
    private var selection: PersistentSelection<
        Filter,
        InventoryBreakdown<BuildingDetailsTab>.Focus
    >

    private var filters: ([FilterLabel], [Never])
    private var entries: [BuildingTableEntry]
    private var details: BuildingDetails?

    private(set) var buildings: [BuildingID: BuildingSnapshot]

    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))

        self.filters = ([], [])
        self.entries = []
        self.details = nil
        self.buildings = [:]
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

    mutating func update(from snapshot: borrowing GameSnapshot, buildings: DynamicContextTable<BuildingContext>) {
        let country: CountryID = snapshot.player

        self.selection.rebuild(
            filtering: buildings,
            entries: &self.buildings,
            details: &self.details,
            default: (buildings.first?.state.tile).map(Filter.location(_:)) ?? .all
        ) {
            if case country? = $0.region?.bloc {
                $0.snapshot
            } else {
                nil
            }
        } update: {
            $0.update(to: $2, from: snapshot) ;
        }
    }
    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.entries.removeAll(keepingCapacity: true)
        for building: BuildingSnapshot in self.buildings.values {
            let entry: BuildingTableEntry = .init(
                id: building.state.id,
                location: building.region.name,
                type: building.type.title,
                state: building.state,
            )
            self.entries.append(entry)
        }
        self.entries.sort(by: self.sort.ascending(_:_:))

        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = self.buildings.values.reduce(into: ([:], nil)) {
            let tile: Address = $1.state.tile
            ; {
                $0 = $0 ?? snapshot.planets[tile].map { .location($0.name ?? "?", tile) }
            } (&$0.locations[tile])
        }
        let filters: (
            location: [FilterLabel],
            Never?
        ) = (
            location: filterable.locations.values.sorted(),
            nil
        )

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
        js[.buildings] = self.entries
        js[.building] = self.details

        js[.filter] = self.selection.filter

        switch self.selection.filter {
        case nil: break
        case .all?: js[.filterlist] = 0
        case .location?: js[.filterlist] = 0
        }

        js[.filterlists] = [self.filters.0]
    }
}
