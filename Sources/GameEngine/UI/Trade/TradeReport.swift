import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

public struct TradeReport {
    private var selection: PersistentSelection<Filter, Void>

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

    mutating func update(from snapshot: borrowing GameSnapshot) {
        let currencies: [Fiat: Currency] = snapshot.countries.state.reduce(into: [:]) {
            $0[$1.currency.id] = $1.currency
        }

        let filterlists: (
            resource: [Resource: ResourceLabel],
            currency: [Fiat: CurrencyLabel]
        ) = snapshot.markets.tradeable.values.reduce(into: ([:], [:])) {
            if  case .good(let id) = $1.id.x {
                $0.resource[id] = snapshot.rules.resources[id].label
            }
            if  case .fiat(let id) = $1.id.y,
                let currency: Currency = currencies[id] {
                $0.currency[id] = currency.label
            }
        }

        self.selection.rebuild(
            filtering: snapshot.markets.tradeable.values,
            entries: &self.markets,
            details: &self.market,
            default: .init(rawValue: .fiat(snapshot.player.currency.id))
        ) {
            guard
            let today: BlocMarket.Interval = $0.state.history.last,
            case .good(let good) = $0.id.x,
            case .fiat(let fiat) = $0.id.y,
            let currency: Currency = currencies[fiat] else {
                return nil
            }

            let resource: ResourceLabel = snapshot.rules.resources[good].label

            return .init(
                id: $0.id,
                name: "\(resource.nameWithIcon) / \(currency.name)",
                price: today.prices,
                volume: today.volume.base.total
            )
        } update: {
            $0.update(from: $2.state, date: snapshot.date)
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
        js[.filter] = self.selection.filter

        switch self.selection.filter?.rawValue {
        case .good?:    js[.filterlist] = 0
        case .fiat?:    js[.filterlist] = 1
        case nil:       break
        }

        js[.filterlists] = [self.filters.0, self.filters.1]
    }
}
