import GameEconomy
import GameMetrics
import GameIDs
import JavaScriptInterop

struct MarketDetails: Identifiable {
    let id: WorldMarket.ID
    var chart: TradingView

    init(id: WorldMarket.ID) {
        self.id = id
        self.chart = .init()
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
    mutating func update(from market: WorldMarket.State, date: GameDate) {
        self.chart.update(with: market, date: date)
    }
}
extension MarketDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case chart
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.chart] = self.chart
    }
}
