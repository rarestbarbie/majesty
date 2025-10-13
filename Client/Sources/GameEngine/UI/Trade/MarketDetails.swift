import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct MarketDetails: Identifiable {
    let id: Market.AssetPair
    var chart: CandlestickChart

    init(id: Market.AssetPair) {
        self.id = id
        self.chart = .init()
    }
}
extension MarketDetails: PersistentReportDetails {
    init(id: Self.ID, open: ()) {
        self.init(id: id)
    }
    var open: () {
        get { () }
        set { }
    }
}
extension MarketDetails {
    mutating func update(from market: Market, date: GameDate) {
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
