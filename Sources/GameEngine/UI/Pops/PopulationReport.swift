import GameIDs
import GameState
import GameTerrain
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

public struct PopulationReport {
    private var selection: PersistentSelection<Filters, InventoryBreakdown<PopDetailsTab>.Focus>

    private var filters: ([FilterLabel], [Never])
    private var columns: (
        TableColumnMetadata<ColumnControl>,
        type: TableColumnMetadata<ColumnControl>,
        race: TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>
    )
    private var details: PopDetails?
    private var entries: [PopTableEntry]
    private var sort: Sort

    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))
        self.filters = ([], [])
        self.columns = (
            .init(id: 0, name: "Size"),
            .init(id: 1, name: "Type"),
            .init(id: 2, name: "Race"),
            .init(id: 3, name: "Militancy"),
            .init(id: 4, name: "Consciousness"),
            .init(id: 5, name: "Jobs"),
            .init(id: 6, name: "Needs"),
        )
        self.details = nil
        self.entries = []
        self.sort = .init()
        self.sort.update(column: .race(""))
        self.sort.update(column: .type(PopOccupation.Politician.descending))
    }
}
extension PopulationReport {
    var columnSelected: Int32? {
        switch self.sort.first {
        case .type?: self.columns.type.id
        case .race?: self.columns.race.id
        case nil: nil
        }
    }
}
extension PopulationReport: PersistentReport {
    mutating func select(request: PopulationReportRequest)  {
        self.selection.select(request.subject, filter: request.filter)
        self.selection.tab = request.details
        self.selection.needs = request.detailsTier

        if  let column: ColumnControl = request.column {
            self.sort.update(column: column)
        }
    }
}
extension PopulationReport {
    mutating func update(from cache: borrowing GameUI.Cache) {
        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = cache.pops.values.reduce(into: ([:], nil)) {
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
            filtering: cache.pops,
            entries: &self.entries,
            details: &self.details,
            default: .init(location: defaultTile, sex: .F),
            sort: self.sort.ascending(_:_:)
        ) {
            guard
            let culture: Culture = cache.rules.pops.cultures[$0.state.race] else {
                return nil
            }

            let entry: PopTableEntry = .init(
                id: $0.state.id,
                type: $0.state.type,
                color: culture.color,
                nat: culture.name,
                une: 1 - $0.stats.employmentBeforeEgress,
                yesterday: $0.state.y,
                today: $0.state.z,
            )

            return entry
        } update: {
            $0.update(to: $2, cache: cache)
        }

        self.columns.type.updateStops(
            columnSelected: self.columnSelected,
            from: self.entries,
            on: \.type.occupation.descending,
            as: ColumnControl.type(_:)
        )
        self.columns.race.updateStops(
            columnSelected: self.columnSelected,
            from: self.entries,
            on: \.nat,
            as: ColumnControl.race(_:)
        )

        self.filters.0 = filters.location
    }
}
extension PopulationReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type

        case columns
        case column
        case pops
        case pop
        case sex
        case sexes

        case filter
        case filterlist
        case filterlists
    }
}
extension PopulationReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Population

        js[.column] = self.columnSelected
        js[.columns] = [
            self.columns.0,
            self.columns.1,
            self.columns.2,
            self.columns.3,
            self.columns.4,
            self.columns.5,
            self.columns.6,
        ]

        js[.pops] = self.entries
        js[.pop] = self.details

        js[.sex] = self.selection.filters.sex.map(Filter.sex(_:))
        js[.sexes] = Sex.allCases.map(Filter.sex(_:))

        // currently there is only one filterlist in the sidebar
        js[.filter] = self.selection.filters.location.map(Filter.location(_:))
        js[.filterlist] = 0
        js[.filterlists] = [self.filters.0]
    }
}
