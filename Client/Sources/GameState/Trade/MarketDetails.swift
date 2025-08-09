import DequeModule
import GameEconomy
import GameEngine
import JavaScriptKit
import JavaScriptInterop

struct MarketDetails {
    let id: Market.AssetPair
    var history: [MarketInterval]
    var min: Double
    var max: Double

    init(id: Market.AssetPair) {
        self.id = id
        self.history = []
        self.min = 0
        self.max = 1
    }
}
extension MarketDetails {
    mutating func update(in context: GameContext, from market: Market) {
        guard let first: Candle<Double> = market.history.first?.log10 else {
            self.history = []
            self.min = 0
            self.max = 1
            return
        }

        self.history.removeAll(keepingCapacity: true)
        self.history.reserveCapacity(market.history.count)
        self.min = first.l
        self.max = first.h

        var date: GameDate = context.date

        for candle: Candle<Double> in market.history.reversed() {
            let interval: MarketInterval = .init(id: date, candle: candle.log10)
            self.history.append(interval)

            date.advance(by: -1)

            if  interval.candle.l < self.min {
                self.min = interval.candle.l
            }
            if  interval.candle.h > self.max {
                self.max = interval.candle.h
            }
        }

        let range: Double = self.max - self.min
        let margin: Double = range * 0.1

        self.min -= margin
        self.max += margin
        self.max = Swift.max(self.max, self.min + 0.000_001)
    }
}
extension MarketDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case history
        case min
        case max
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.history] = self.history
        js[.min] = self.min
        js[.max] = self.max
    }
}
