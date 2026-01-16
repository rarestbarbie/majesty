import ColorText
import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TimeSeries {
    @usableFromInline var history: [TimeSeriesFrame]
    @usableFromInline var min: Double
    @usableFromInline var max: Double
    @usableFromInline var ticks: [TickRule]

    @inlinable public init() {
        self.history = []
        self.min = 0
        self.max = 1
        self.ticks = []
    }
}
extension TimeSeries: TickRuleAssignable {}
extension TimeSeries {
    @inlinable public mutating func update<Frame>(
        with history: some RandomAccessCollection<Frame>,
        date: GameDate,
        linear value: (Frame) -> Double
    ) {
        guard
        let last: Frame = history.last else {
            self.history = []
            self.min = 0
            self.max = 1
            self.ticks = []
            return
        }

        let y: Double = value(last)

        self.history.removeAll(keepingCapacity: true)
        self.history.reserveCapacity(history.count)
        self.min = y
        self.max = y

        var date: GameDate = date

        for source: Frame in history.reversed() {
            let frame: TimeSeriesFrame = .init(
                id: date,
                value: value(source)
            )

            self.history.append(frame)

            date.advance(by: -1)

            if  frame.value < self.min {
                self.min = frame.value
            }
            if  frame.value > self.max {
                self.max = frame.value
            }
        }

        let range: Double = self.max - self.min
        let margin: Double = range * 0.1

        self.min -= margin
        self.max += margin
        self.max = Swift.max(self.max, self.min + 0.000_001)
        self.ticks = self.tickLinearly(current: (y: value(last), style: .em))
    }
}
extension TimeSeries: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case history
        case min
        case max
        case ticks
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.history] = self.history
        js[.min] = self.min
        js[.max] = self.max
        js[.ticks] = self.ticks
    }
}
