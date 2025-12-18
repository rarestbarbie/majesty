import GameEconomy
import GameIDs
import GameState
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct ProductionReport {
    private var selection: PersistentSelection<
        Filter,
        InventoryBreakdown<FactoryDetailsTab>.Focus
    >

    private var filters: ([FilterLabel], [Never])
    private var entries: [FactoryTableEntry]
    private var details: FactoryDetails?

    private(set) var factories: [FactoryID: FactorySnapshot]


    init() {
        self.selection = .init(defaultFocus: .init(tab: .Inventory, needs: .l))
        self.filters = ([], [])
        self.entries = []
        self.details = nil
        self.factories = [:]
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

    mutating func update(from snapshot: borrowing GameSnapshot, factories: DynamicContextTable<FactoryContext>) {
        let country: CountryID = snapshot.player
        self.selection.rebuild(
            filtering: factories,
            entries: &self.factories,
            details: &self.details,
            default: (factories.first?.state.tile).map(Filter.location(_:)) ?? .all
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
        for factory: FactorySnapshot in self.factories.values {
            let equity: Equity<LEI>.Statistics = factory.equity
            let liquidationProgress: Double? = factory.state.liquidation.map {
                $0.burning == 0 ? 1 : Double(
                    $0.burning - equity.shareCount
                ) / Double($0.burning)
            }

            let entry: FactoryTableEntry = .init(
                id: factory.state.id,
                location: factory.region.name,
                type: factory.type.title,
                size: factory.state.size,
                liquidationProgress: liquidationProgress,
                yesterday: factory.state.y,
                today: factory.state.z,
                workers: factory.workers.map(FactoryWorkers.init(aggregate:)),
                clerks: factory.clerks.map(FactoryWorkers.init(aggregate:))
            )
            self.entries.append(entry)
        }
        self.entries.sort(by: self.sort.ascending(_:_:))

        let filterable: (
            locations: [Address: FilterLabel],
            Never?
        ) = self.factories.values.reduce(into: ([:], nil)) {
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

        js[.filter] = self.selection.filter

        switch self.selection.filter {
        case nil: break
        case .all?: js[.filterlist] = 0
        case .location?: js[.filterlist] = 0
        }

        js[.filterlists] = [self.filters.0]
    }
}
