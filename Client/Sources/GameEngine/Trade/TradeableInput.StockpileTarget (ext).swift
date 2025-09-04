import GameEconomy
import Random

extension TradeableInput.StockpileTarget {
    static func random(
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
