import DequeModule
import Fraction
import GameIDs
import LiquidityPool
import RealModule

@frozen public struct WorldMarket: Identifiable {
    public let id: ID
    public let dividend: Fraction
    @usableFromInline var history: Deque<Aggregate>
    @usableFromInline var current: Candle<Double>
    @usableFromInline var pool: LiquidityPool

    @usableFromInline var y: Interval
    @usableFromInline var z: Interval.Indicators

    @inlinable init(
        id: ID,
        dividend: Fraction,
        history: Deque<Aggregate>,
        current: Candle<Double>,
        pool: LiquidityPool,
        y: Interval,
        z: Interval.Indicators,
    ) {
        self.id = id
        self.dividend = dividend
        self.pool = pool
        self.history = history
        self.current = current
        self.y = y
        self.z = z
    }
}
extension WorldMarket {
    @inlinable public init(state: State) {
        let pool: LiquidityPool = .init(
            assets: state.z.assets,
            volume: .init(),
            fee: state.fee
        )
        self.init(
            id: state.id,
            dividend: state.dividend,
            history: state.history,
            current: .open(pool.price),
            pool: pool,
            y: state.y,
            z: state.z.indicators
        )
    }
    @inlinable public var state: State {
        .init(
            id: self.id,
            dividend: self.dividend,
            history: self.history,
            fee: self.pool.fee,
            y: self.y,
            z: .init(assets: self.pool.assets, indicators: self.z)
        )
    }
}
extension WorldMarket {
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
extension WorldMarket {
    @inlinable public var price: Double { self.current.c }
}
extension WorldMarket {
    @inlinable public mutating func turn(history: Int) {
        if  self.history.count >= history {
            self.history.removeFirst(self.history.count - history + 1)
        }

        let interval: Aggregate = .init(
            volume: self.pool.volume,
            prices: self.current,
        )

        self.y = .init(assets: self.pool.assets, indicators: self.z)
        self.z.update(from: self.pool)

        self.current = .open(self.pool.price)
        self.pool.assets.drain(self.dividend)
        self.pool.volume.reset()

        self.history.append(interval)
    }
}
