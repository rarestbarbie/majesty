import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

public struct TradeReport {
    private var currencies: [CurrencyLabel]
    private var resources: [ResourceLabel]

    private var markets: [MarketTableEntry]
    private var market: MarketDetails?
    private var filter: Market.Asset?
    private var cursor: [Market.Asset: Market.AssetPair]

    init() {
        self.currencies = []
        self.resources = []
        self.markets = []
        self.market = nil
        self.filter = nil
        self.cursor = [:]
    }
}
extension TradeReport: PersistentReport {
    mutating func select(
        subject: Market.AssetPair?,
        details: Never?,
        filter: Market.Asset?
    ) {
        if  let filter: Market.Asset {
            self.filter = filter
        }

        if  let subject: Market.AssetPair {
            // We were specifically asked to select a market, so we are done
            self.market = .init(id: subject)
            return
        }

        guard
        let filter: Market.Asset = self.filter else {
            return
        }

        guard
        let id: Market.AssetPair = self.market?.id, id.x != filter, id.y != filter else {
            // The currently selected market is still valid.
            return
        }

        if  let saved: Market.AssetPair = self.cursor[filter] {
            self.market = .init(id: saved)
        } else {
            self.market = nil
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.markets.removeAll()

        var resourcesTraded: [Resource: ResourceLabel] = [:]
        var currenciesTraded: [Fiat: CurrencyLabel] = [:]
        let currencies: [Fiat: Country.Currency] = snapshot.countries.state.reduce(
            into: [:]
        ) { $0[$1.currency.id] = $1.currency }
        let currencyPlayer: Fiat? = snapshot.countries.state[snapshot.player]?.currency.id

        for market: Market in snapshot.markets.tradeable.values {
            guard
            let today: Market.Interval = market.history.last,
            case .good(let good) = market.id.x,
            case .fiat(let fiat) = market.id.y,
            let currency: Country.Currency = currencies[fiat] else {
                continue
            }

            let resource: ResourceLabel = snapshot.rules[good]

            resourcesTraded[good] = resource
            currenciesTraded[fiat] = currency.label

            switch self.filter {
            case nil:           break
            case .good(good)?:  break
            case .fiat(fiat)?:  break
            case _?:            continue
            }

            self.markets.append(
                .init(
                    id: market.id,
                    name: "\(resource.nameWithIcon) / \(currency.name)",
                    price: today.prices,
                    volume: today.volume.base.total
                )
            )

            switch self.market?.id {
            case nil:
                // If no market is selected, select the first one denominated in the player’s
                // national currency. If the filter is set to a specific currency, take the
                // first market regardless of the currency.
                if  case .fiat? = self.filter  {
                } else if
                    case fiat? = currencyPlayer {
                } else {
                    continue
                }

                self.market = .init(id: market.id)
                fallthrough

            case market.id?:
                self.market?.update(from: market, date: snapshot.date)

            case _?:
                continue
            }
        }

        //  If we have a valid market selected, save it in the cursor state.
        if  let subject: Market.AssetPair = self.market?.id,
            let filter: Market.Asset = self.filter {
            self.cursor[filter] = subject
        }

        self.currencies = currenciesTraded.values.sorted { $0.name < $1.name }
        self.resources = resourcesTraded.values.sorted { $0.id < $1.id }
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
        js[.filter] = self.filter

        switch self.filter {
        case .good?:    js[.filterlist] = 0
        case .fiat?:    js[.filterlist] = 1
        case nil:       break
        }

        js[.filterlists] = [
            self.resources.lazy.map(MarketFilterLabel.resource(_:)),
            self.currencies.lazy.map(MarketFilterLabel.currency(_:))
        ]
    }
}
