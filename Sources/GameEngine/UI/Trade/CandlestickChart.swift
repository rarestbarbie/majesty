import DequeModule
import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct CandlestickChart {
    var history: [CandlestickChartInterval]
    var min: Double
    var max: Double
    var maxv: Int64

    init() {
        self.history = []
        self.min = 0
        self.max = 1
        self.maxv = 1
    }
}
extension CandlestickChart {
    mutating func update(with market: BlocMarket.State, date: GameDate) {
        guard let first: BlocMarket.Interval = market.history.first else {
            self.history = []
            self.min = 0
            self.max = 1
            return
        }

        let firstCandle: Candle<Double> = first.prices.log10

        self.history.removeAll(keepingCapacity: true)
        self.history.reserveCapacity(market.history.count)
        self.min = firstCandle.l
        self.max = firstCandle.h
        self.maxv = Swift.max(first.volume.base.total, 1)

        var date: GameDate = date

        for interval: BlocMarket.Interval in market.history.reversed() {
            let interval: CandlestickChartInterval = .init(
                id: date,
                prices: interval.prices.log10,
                volume: interval.volume.base.total
            )

            self.history.append(interval)

            date.advance(by: -1)

            if  interval.prices.l < self.min {
                self.min = interval.prices.l
            }
            if  interval.prices.h > self.max {
                self.max = interval.prices.h
            }
            if  interval.volume > self.maxv {
                self.maxv = interval.volume
            }
        }

        let range: Double = self.max - self.min
        let margin: Double = range * 0.1

        self.min -= margin
        self.max += margin
        self.max = Swift.max(self.max, self.min + 0.000_001)
    }
}
extension CandlestickChart: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case history
        case min
        case max
        case maxv
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.history] = self.history
        js[.min] = self.min
        js[.max] = self.max
        js[.maxv] = self.maxv
    }
}
