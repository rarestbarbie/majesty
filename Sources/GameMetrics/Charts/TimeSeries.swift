import ColorReference
import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TimeSeries {
    @usableFromInline var channels: [TimeSeriesChannel]
    @usableFromInline var range: (min: Double, max: Double)
    @usableFromInline var ticks: [TickRule]

    @inlinable public init() {
        self.channels = []
        self.range = (min: 0, max: 1)
        self.ticks = []
    }
}
extension TimeSeries: TickRuleAssignable {}
extension TimeSeries {
    @inlinable mutating func reset() {
        self.channels = []
        self.range = (min: 0, max: 1)
        self.ticks = []
    }
}
extension TimeSeries {
    @inlinable public mutating func update<Frame>(
        with history: some RandomAccessCollection<Frame>,
        date: GameDate,
        label: ColorReference? = nil,
        digits: Int = 3,
        linear value: (Frame) -> Double
    ) {
        self.update(
            with: history,
            date: date,
            labels: label.map { [$0] } ?? [],
            digits: digits
        ) {
            CollectionOfOne<Double>.init(value($0))
        }
    }
    @inlinable public mutating func update<Frame, Values>(
        with history: some RandomAccessCollection<Frame>,
        date: GameDate,
        labels: [ColorReference],
        digits: Int = 3,
        linear value: (Frame) -> Values
    ) where Values: Collection<Double> {
        self.reset()

        guard
        let last: Values = history.last.map(value) else {
            return
        }

        self.channels = []
        self.channels.reserveCapacity(last.count)

        var labels: [ColorReference].Iterator = labels.makeIterator()
        var label: ColorReference? = labels.next()
        var range: (min: Double, max: Double)? = nil
        var index: Int = 0
        let rules: [(y: Double, label: ColorReference?)] = last.map {
            index += 1
            // this is just to initialize it with some point we know is in-range
            range = ($0, $0)
            self.channels.append(.init(id: index, frames: [], label: label))
            // have to iterate this way because calling `next` after `nil` is undefined behavior
            if  let next: ColorReference = label {
                label = labels.next()
                return (y: $0, label: next)
            } else {
                return (y: $0, label: nil)
            }
        }

        if  let range: (min: Double, max: Double) {
            self.range = range
        } else {
            return
        }

        for i: Int in self.channels.indices {
            self.channels[i].frames.reserveCapacity(history.count)
        }

        var date: GameDate = date
        for source: Frame in history.reversed() {
            for (i, value): (Int, Double) in zip(self.channels.indices, value(source)) {
                if  self.range.min > value {
                    self.range.min = value
                }
                if  self.range.max < value {
                    self.range.max = value
                }
                let frame: TimeSeriesFrame = .init(
                    id: date,
                    value: value
                )

                self.channels[i].frames.append(frame)
            }

            date.advance(by: -1)
        }

        let margin: Double = (self.range.max - self.range.min) * 0.1

        self.range.min -= margin
        self.range.max += margin
        self.range.max = max(self.range.max, self.range.min + 0.000_001)
        self.ticks = self.tickLinearly(current: rules, digits: digits)
    }
}
extension TimeSeries: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case channels
        case min
        case max
        case ticks
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.channels] = self.channels.lazy.map { $0.path(in: self.range) }
        js[.min] = self.range.min
        js[.max] = self.range.max
        js[.ticks] = self.ticks
    }
}
