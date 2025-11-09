import DequeModule
import Fraction
import LiquidityPool
import RealModule

extension BlocMarket {
    @frozen public struct State {
        public let id: ID
        public let dividend: Fraction
        public let history: Deque<Interval>
        public let capital: LiquidityPool.Assets
        public let fee: Fraction

        @inlinable public init(
            id: ID,
            dividend: Fraction,
            history: Deque<Interval>,
            capital: LiquidityPool.Assets,
            fee: Fraction,
        ) {
            self.id = id
            self.dividend = dividend
            self.history = history
            self.capital = capital
            self.fee = fee
        }
    }
}
