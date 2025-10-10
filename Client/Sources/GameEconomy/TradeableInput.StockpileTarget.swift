import Random

extension TradeableInput {
    @frozen public struct StockpileTarget {
        public let lower: Int64
        public let today: Int64
        public let upper: Int64

        @inlinable public init(lower: Int64, today: Int64, upper: Int64) {
            self.lower = lower
            self.today = today
            self.upper = upper
        }
    }
}
extension TradeableInput.StockpileTarget {
    @inlinable public static func random(
        in range: ClosedRange<Int64>,
        using generator: inout PseudoRandom
    ) -> Self {
        .init(
            lower: range.lowerBound,
            today: generator.int64(in: range),
            upper: range.upperBound
        )
    }
}
