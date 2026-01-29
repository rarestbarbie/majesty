import GameEconomy
import GameIDs
import JavaScriptInterop

public struct TradeReport: Sendable {
    private var selection: PersistentLayeredSelection<Filters, Void>

    private var filters: ([MarketFilterLabel], [MarketFilterLabel])
    private var markets: [MarketTableEntry]
    private var market: MarketDetails?

    init() {
        self.selection = .init(defaultFocus: ())
        self.filters = ([], [])
        self.markets = []
        self.market = nil
    }
}
extension TradeReport: PersistentReport {
    mutating func select(request: TradeReportRequest) {
        self.selection.select(request.subject, filter: request.filter)
    }

    mutating func update(from cache: borrowing GameUI.Cache) {
        let filterlists: (
            resource: [Resource: ResourceLabel],
            currency: [CurrencyID: CurrencyLabel]
        ) = cache.worldMarkets.values.reduce(into: ([:], [:])) {
            if  case .good(let id) = $1.id.x {
                $0.resource[id] = cache.rules.resources[id].label
            }
            if  case .fiat(let id) = $1.id.y,
                let currency: Currency = cache.currencies[id] {
                $0.currency[id] = currency.label
            }
        }

        self.selection.rebuild(
            filtering: cache.worldMarkets,
            entries: &self.markets,
            details: &self.market,
            sort: { $0.name < $1.name }
        ) {
            guard
            let market: WorldMarketSnapshot = $0.snapshot,
            let name: String = cache.context.name(market.id) else {
                return nil
            }
            return .init(
                id: $0.id,
                name: name,
                open: market.price.o,
                close: market.price.c,
                volume: market.Δ.v,
                velocity: market.Δ.velocity,
            )
        } filter: {
            $0.asset = $0.asset ?? .fiat(cache.playerCountry.currency)
        } update: {
            $0.update(from: $2, context: cache.context)
        }

        self.filters.0 = filterlists.resource.values.map(MarketFilterLabel.resource(_:))
        self.filters.1 = filterlists.currency.values.map(MarketFilterLabel.currency(_:))

        self.filters.0.sort()
        self.filters.1.sort()
    }
}
extension TradeReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type

        case markets
        case market
        case filter
        case filterlist
        case filterlists
    }
}
extension TradeReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Trade
        js[.markets] = self.markets
        js[.market] = self.market
        js[.filter] = self.selection.filters.asset.map(Filter.asset(_:))

        switch self.selection.filters.asset {
        case .good?: js[.filterlist] = 0
        case .fiat?: js[.filterlist] = 1
        case nil: break
        }

        js[.filterlists] = [self.filters.0, self.filters.1]
    }
}
