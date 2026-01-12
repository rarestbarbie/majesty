import DequeModule
import Fraction
import LiquidityPool
import RealModule

extension WorldMarket {
    @frozen public struct State {
        public let id: ID
        public let dividend: Fraction
        public let history: Deque<Aggregate>
        public let fee: Fraction

        public let y: Interval
        public let z: Interval

        @inlinable public init(
            id: ID,
            dividend: Fraction,
            history: Deque<Aggregate>,
            fee: Fraction,
            y: Interval,
            z: Interval,
        ) {
            self.id = id
            self.dividend = dividend
            self.history = history
            self.fee = fee

            self.y = y
            self.z = z
        }
    }
}
