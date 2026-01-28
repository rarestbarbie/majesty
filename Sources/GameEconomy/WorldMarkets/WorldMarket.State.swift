import DequeModule
import Fraction
import LiquidityPool
import RealModule

extension WorldMarket {
    @frozen public struct State {
        public let id: ID
        public let history: Deque<Aggregate>
        public let y: Interval
        public let z: Interval

        @inlinable public init(
            id: ID,
            history: Deque<Aggregate>,
            y: Interval,
            z: Interval,
        ) {
            self.id = id
            self.history = history
            self.y = y
            self.z = z
        }
    }
}
