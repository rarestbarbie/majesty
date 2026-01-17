import ColorText
import D
import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop
import RealModule

@frozen public struct TradingView {
    @usableFromInline var history: [Candlestick]
    @usableFromInline var min: Double
    @usableFromInline var max: Double
    @usableFromInline var maxv: Int64
    @usableFromInline var ticks: [TickRule]

    @inlinable public init() {
        self.history = []
        self.min = 0
        self.max = 1
        self.maxv = 1
        self.ticks = []
    }
}
extension TradingView: TickRuleAssignable {}
extension TradingView {
    public mutating func update(with market: WorldMarket.State, date: GameDate) {
        guard
        let last: WorldMarket.Aggregate = market.history.last else {
            self.history = []
            self.min = 0
            self.max = 1
            self.ticks = []
            return
        }

        let lastCandle: Candle<Double> = last.prices.log10

        self.history.removeAll(keepingCapacity: true)
        self.history.reserveCapacity(market.history.count)
        self.min = lastCandle.l
        self.max = lastCandle.h
        self.maxv = Swift.max(last.volume.base.total, 1)

        var date: GameDate = date

        for frame: WorldMarket.Aggregate in market.history.reversed() {
            let logarithmic: Candlestick = .init(
                id: date,
                prices: frame.prices.log10,
                volume: frame.volume.base.total
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
        self.ticks = self.tickLogarithmically(
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
    @frozen public enum ObjectKey: JSString, Sendable {
        case history
        case min
        case max
        case maxv
        case ticks
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.history] = self.history
        js[.min] = self.min
        js[.max] = self.max
        js[.maxv] = self.maxv
        js[.ticks] = self.ticks
    }
}
