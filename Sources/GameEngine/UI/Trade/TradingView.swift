import ColorText
import D
import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop
import RealModule

struct TradingView {
    var history: [Candlestick]
    var min: Double
    var max: Double
    var maxv: Int64
    var ticks: [TradingViewTick]

    init() {
        self.history = []
        self.min = 0
        self.max = 1
        self.maxv = 1
        self.ticks = []
    }
}
extension TradingView {
    private static var detail: Double { 1 / 5 }
    private static func ticks(
        log: (min: Double, max: Double),
        current: (y: Double, style: ColorText.Style?)
    ) -> [TradingViewTick] {
        let linear: (min: Double, max: Double) = (.exp10(log.min), .exp10(log.max))
        let range: Double = linear.max - linear.min
        let scale: Double = Self.detail * range

        let decade: Double = .exp10(Double.log10(scale).rounded(.down))

        if  decade <= 0 {
            // this is possible, if scale is 0, which causes `log10` to return `-inf`
            return []
        }

        let step: Double
        switch scale / decade {
        case ...1: step = decade
        case ...3: step = decade * 2
        default: step = decade * 5
        }

        let steps: (first: Int64, last: Int64) = (
            Int64.init((linear.min / step).rounded(.up)),
            Int64.init((linear.max / step).rounded(.down))
        )
        if  steps.last < steps.first {
            return []
        }

        var ticks: [TradingViewTick] = []
        ;   ticks.reserveCapacity(Int.init(steps.last - steps.first) + 1)

        for i: Int64 in steps.first ... steps.last {
            let y: Double = Double.init(i) * step
            let linear: Decimal? = .init(rounding: y, places: 2)
            ticks.append(
                TradingViewTick.init(
                    id: 1 + Int.init(i - steps.first),
                    price: Double.log10(y),
                    label: linear.map { "\($0[..])" } ?? "",
                    style: nil
                )
            )
        }

        ticks.append(
            TradingViewTick.init(
                id: 0,
                price: Double.log10(current.y),
                label: Decimal.init(rounding: current.y, places: 2).map { "\($0[..])" } ?? "",
                style: current.style
            )
        )

        return ticks
    }
}
extension TradingView {
    mutating func update(with market: WorldMarket.State, date: GameDate) {
        guard
        let first: WorldMarket.Aggregate = market.history.first,
        let last: WorldMarket.Aggregate = market.history.last else {
            self.history = []
            self.min = 0
            self.max = 1
            self.ticks = []
            return
        }

        let firstCandle: Candle<Double> = first.prices.log10

        self.history.removeAll(keepingCapacity: true)
        self.history.reserveCapacity(market.history.count)
        self.min = firstCandle.l
        self.max = firstCandle.h
        self.maxv = Swift.max(first.volume.base.total, 1)

        var date: GameDate = date

        for linear: WorldMarket.Aggregate in market.history.reversed() {
            let logarithmic: Candlestick = .init(
                id: date,
                prices: linear.prices.log10,
                volume: linear.volume.base.total
            )

            self.history.append(logarithmic)

            date.advance(by: -1)

            if  logarithmic.prices.l < self.min {
                self.min = logarithmic.prices.l
            }
            if  logarithmic.prices.h > self.max {
                self.max = logarithmic.prices.h
            }
            if  logarithmic.volume > self.maxv {
                self.maxv = logarithmic.volume
            }
        }

        let range: Double = self.max - self.min
        let margin: Double = range * 0.1

        self.min -= margin
        self.max += margin
        self.max = Swift.max(self.max, self.min + 0.000_001)
        self.ticks = Self.ticks(
            log: (min: self.min, max: self.max),
            current: (
                y: last.prices.c,
                style:
                    last.prices.c > last.prices.o ? .pos :
                    last.prices.c < last.prices.o ? .neg : nil
            )
        )
    }
}
extension TradingView: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case history
        case min
        case max
        case maxv
        case ticks
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.history] = self.history
        js[.min] = self.min
        js[.max] = self.max
        js[.maxv] = self.maxv
        js[.ticks] = self.ticks
    }
}
