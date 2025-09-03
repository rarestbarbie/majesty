import GameEconomy
import JavaScriptKit
import JavaScriptInterop

struct MarketDetails {
    let id: Market.AssetPair
    var chart: CandlestickChart

    init(id: Market.AssetPair) {
        self.id = id
        self.chart = .init()
    }
}
extension MarketDetails {
    mutating func update(in context: GameContext, from market: Market) {
        self.chart.update(with: market, date: context.date)
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
