import DequeModule
import Fraction
import GameIDs
import LiquidityPool
import RealModule

@frozen public struct BlocMarket: Identifiable {
    public let id: ID
    public let dividend: Fraction
    @usableFromInline var history: Deque<Interval>
    @usableFromInline var current: Candle<Double>
    @usableFromInline var pool: LiquidityPool

    @inlinable init(
        id: ID,
        dividend: Fraction,
        history: Deque<Interval>,
        current: Candle<Double>,
        pool: LiquidityPool,
    ) {
        self.id = id
        self.dividend = dividend
        self.pool = pool
        self.history = history
        self.current = current
    }
}
extension BlocMarket {
    @inlinable public init(state: State) {
        let pool: LiquidityPool = .init(
            assets: state.capital,
            volume: .init(),
            fee: state.fee
        )
        self.init(
            id: state.id,
            dividend: state.dividend,
            history: state.history,
            current: .open(pool.price),
            pool: pool,
        )
    }
    @inlinable public var state: State {
        .init(
            id: self.id,
            dividend: self.dividend,
            history: self.history,
            capital: self.pool.assets,
            fee: self.pool.fee,
        )
    }
}
extension BlocMarket {
    /// Unlike ``pool``, this property updates the candle on mutation.
    var canonical: LiquidityPool {
        _read {
            yield self.pool
        }
        _modify {
            yield &self.pool
            self.current.update(self.pool.price)
        }
    }

    /// Unlike `pool.conjugated`, this property updates the candle on mutation.
    var conjugate: LiquidityPool {
        _read {
            yield self.pool.conjugated
        }
        _modify {
            yield &self.pool.conjugated
            self.current.update(self.pool.price)
        }
    }
}
extension BlocMarket {
    @inlinable public var price: Double { self.current.c }
}
extension BlocMarket {
    @inlinable public mutating func turn(history: Int) {
        if  self.history.count >= history {
            self.history.removeFirst(self.history.count - history + 1)
        }

        let interval: Interval = .init(
            prices: self.current,
            volume: self.pool.volume,
            liquidity: .sqrt(
                Double.init(self.pool.assets.quote) * Double.init(self.pool.assets.base)
            )
        )

        self.current = .open(self.pool.price)
        self.pool.assets.drain(self.dividend)
        self.pool.volume.reset()

        self.history.append(interval)
    }
}
