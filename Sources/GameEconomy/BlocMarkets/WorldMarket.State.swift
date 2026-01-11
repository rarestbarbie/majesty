import DequeModule
import Fraction
import LiquidityPool
import RealModule

extension WorldMarket {
    @frozen public struct State {
        public let id: ID
        public let dividend: Fraction
        public let history: Deque<Interval>
        public let fee: Fraction

        public let yesterday: Indicators
        public let today: Indicators
        public let units: LiquidityPool.Assets

        @inlinable public init(
            id: ID,
            dividend: Fraction,
            history: Deque<Interval>,
            fee: Fraction,
            yesterday: Indicators,
            today: Indicators,
            units: LiquidityPool.Assets,
        ) {
            self.id = id
            self.dividend = dividend
            self.history = history
            self.fee = fee

            self.yesterday = yesterday
            self.today = today
            self.units = units
        }
    }
}
