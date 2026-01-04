import GameEconomy
import GameIDs
import GameState
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct ProductionReport {
    private var selection: PersistentLayeredSelection<
        Filters,
        LegalEntityFocus<FactoryDetailsTab>
    >

    private var filters: ([FilterLabel], [Never])
    private var entries: [FactoryTableEntry]
    private var details: FactoryDetails?

    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))
        self.filters = ([], [])
        self.entries = []
        self.details = nil
    }
}
extension ProductionReport: PersistentReport {
    mutating func select(request: ProductionReportRequest) {
        self.selection.select(request.subject, filter: request.filter)
        self.selection.tab = request.details
        self.selection.needs = request.detailsTier
    }
}
extension ProductionReport {
    private var sort: Sort {
        .init()
    }

    mutating func update(from cache: borrowing GameUI.Cache) {
        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = cache.factories.values.reduce(into: ([:], nil)) {
            $0.locations[$1.tile] = .location($1.region.name, $1.tile)
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
            filtering: cache.factories,
            entries: &self.entries,
            details: &self.details,
            sort: self.sort.ascending(_:_:)
        ) {
            let equity: Equity<LEI>.Snapshot = $0.equity
            let liquidationProgress: Double? = $0.liquidation.map {
                $0.burning == 0 ? 1 : Double(
                    $0.burning - equity.shareCount
                ) / Double($0.burning)
            }

            let entry: FactoryTableEntry = .init(
                id: $0.id,
                location: $0.region.name,
                type: $0.metadata.title,
                size: $0.size,
                liquidationProgress: liquidationProgress,
                yesterday: $0.y,
                today: $0.z,
                workers: $0.workers.map(FactoryWorkers.init(aggregate:)),
                clerks: $0.clerks.map(FactoryWorkers.init(aggregate:))
            )

            return entry
        } filter: {
            $0.location = $0.location ?? defaultTile
        } update: {
            $0.update(to: $2, cache: cache)
        }

        self.filters.0 = filters.location
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
        js[.factories] = self.entries
        js[.factory] = self.details

        // currently there is only one filterlist in the sidebar
        js[.filter] = self.selection.filters.location.map(Filter.location(_:))
        js[.filterlist] = 0
        js[.filterlists] = [self.filters.0]
    }
}
