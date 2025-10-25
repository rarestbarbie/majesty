import GameIDs
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct PopulationReport {
    private var selection: PersistentSelection<Filter, PopDetailsTab>

    private var filters: ([FilterLabel], [Never])
    private var columns: (
        TableColumnMetadata<ColumnControl>,
        type: TableColumnMetadata<ColumnControl>,
        race: TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>,
        TableColumnMetadata<ColumnControl>
    )
    private var sort: Sort
    private var pops: [PopTableEntry]
    private var pop: PopDetails?

    init() {
        self.selection = .init(defaultTab: .Inventory)
        self.filters = ([], [])
        self.columns = (
            .init(id: 0, name: "Size"),
            .init(id: 1, name: "Type"),
            .init(id: 2, name: "Race"),
            .init(id: 3, name: "Location"),
            .init(id: 4, name: "Militancy"),
            .init(id: 5, name: "Consciousness"),
            .init(id: 6, name: "Unemp."),
            .init(id: 7, name: "Net worth"),
            .init(id: 8, name: "Needs"),
            .init(id: 9, name: ""),
            .init(id: 10, name: ""),
        )
        self.sort = .init()
        self.pops = []
        self.pop = nil
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
        self.selection.select(request.subject, filter: request.filter, detailsTab: request.details)
        if  let column: ColumnControl = request.column {
            self.sort.update(column: column)
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        let country: CountryProperties = snapshot.player

        let filterlists: (
            location: [Address: FilterLabel],
            Never?
        ) = snapshot.pops.reduce(into: ([:], nil)) {
            let tile: Address = $1.state.tile
            if case country.id? = $1.governedBy?.id {
                {
                    $0 = $0 ?? snapshot.planets[tile].map { .location($0.name ?? "?", tile) }
                } (&$0.location[tile])
            }
        }

        self.selection.rebuild(
            filtering: snapshot.pops,
            entries: &self.pops,
            details: &self.pop,
            default: .all
        ) {
            guard case country.id? = $0.governedBy?.id else {
                return nil
            }
            guard
            let planet: PlanetContext = snapshot.planets[$0.state.tile.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[$0.state.tile.tile],
            let culture: Culture = snapshot.cultures.state[$0.state.nat] else {
                return nil
            }

            return PopTableEntry.init(
                id: $0.state.id,
                location: tile.name ?? planet.state.name,
                type: $0.state.type,
                color: culture.color,
                nat: $0.state.nat,
                une: $0.unemployment,
                yesterday: $0.state.yesterday,
                today: $0.state.today,
                jobs: $0.state.factories.values.map {
                    .init(
                        name: snapshot.factories[$0.id]?.type.name ?? "Unknown",
                        size: $0.count,
                        hire: $0.hired,
                        fire: $0.fired,
                        quit: $0.quit,
                    )
                },
            )
        } update: {
            $0.update(to: $2, from: snapshot)
        }

        self.pops.sort(by: self.sort.ascending)

        self.filters.0 = [.all] + filterlists.location.values.sorted()
        self.columns.type.updateStops(
            columnSelected: self.columnSelected,
            from: self.pops,
            on: \.type,
            as: ColumnControl.type(_:)
        )
        self.columns.race.updateStops(
            columnSelected: self.columnSelected,
            from: self.pops,
            on: \.nat,
            as: ColumnControl.race(_:)
        )
    }
}
extension PopulationReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type

        case columns
        case column
        case pops
        case pop

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
            self.columns.7,
            self.columns.8,
            self.columns.9,
            self.columns.10,
        ]

        js[.pops] = self.pops
        js[.pop] = self.pop

        js[.filter] = self.selection.filter

        switch self.selection.filter {
        case nil: break
        case .all?: js[.filterlist] = 0
        case .location?: js[.filterlist] = 0
        }

        js[.filterlists] = [self.filters.0]
    }
}
