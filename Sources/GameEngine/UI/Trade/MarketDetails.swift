import D
import GameEconomy
import GameMetrics
import GameIDs
import GameUI
import JavaScriptInterop

struct MarketDetails: Identifiable {
    let id: WorldMarket.ID
    private var name: String?
    private var chart: TradingView
    private var terms: [Term]

    init(id: WorldMarket.ID) {
        self.id = id
        self.name = nil
        self.chart = .init()
        self.terms = []
    }
}
extension MarketDetails: PersistentReportDetails {
    init(id: Self.ID, focus: ()) {
        self.init(id: id)
    }
    mutating func refocus(on focus: ()) {
    }
}
extension MarketDetails {
    mutating func update(from market: WorldMarket, context: GameUI.CacheContext) {
        self.chart.update(with: market.state, date: context.date)
        self.name = context.name(market.id)

        guard
        let market: WorldMarketSnapshot = market.snapshot else {
            self.terms = []
            return
        }

        self.terms = Term.list {
            $0[.fee, -, tooltip: .MarketFee] = market.Δ.fee[%2]
            $0[.liquidity, +, tooltip: .MarketLiquidity] = market.Δ.assets.liquidity[/3..2]
        }
    }
}
extension MarketDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case chart
        case terms
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.chart] = self.chart
        js[.terms] = self.terms
    }
}
