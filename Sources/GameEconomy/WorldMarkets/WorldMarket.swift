import DequeModule
import Fraction
import GameIDs
import LiquidityPool
import RealModule

@frozen public struct WorldMarket: Identifiable {
    public let id: ID
    public let shape: Shape

    @usableFromInline var history: Deque<Aggregate>
    @usableFromInline var current: Candle<Double>
    @usableFromInline var pool: LiquidityPool

    @usableFromInline var y: Interval
    @usableFromInline var z: Interval.Indicators

    private init(
        id: ID,
        shape: Shape,
        history: Deque<Aggregate>,
        current: Candle<Double>,
        pool: LiquidityPool,
        y: Interval,
        z: Interval.Indicators,
    ) {
        self.id = id
        self.shape = shape
        self.pool = pool
        self.history = history
        self.current = current
        self.y = y
        self.z = z
    }
}
extension WorldMarket {
    init(state: State, shape: Shape) {
        let pool: LiquidityPool = .init(
            assets: state.z.assets,
            volume: .init(),
            fee: state.z.fee,
        )
        self.init(
            id: state.id,
            shape: shape,
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
            history: self.history,
            y: self.y,
            z: .init(from: self.pool, indicators: self.z)
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
    mutating func turn() {
        self.y = .init(from: self.pool, indicators: self.z)
        self.pool.fee = self.shape.fee(velocity: self.y.velocity)
    }

    mutating func advance(history: Int) -> Quote {
        if  self.history.count >= history {
            self.history.removeFirst(self.history.count - history + 1)
        }

        let interval: Aggregate = .init(
            volume: self.pool.volume,
            prices: self.current,
        )
        self.history.append(interval)
        self.current = .open(self.pool.price)
        self.z.update(from: self.pool)

        let drained: Quote = .init(
            units: self.shape.drain(assets: self.pool.assets.base, volume: self.z.vb),
            value: self.shape.drain(assets: self.pool.assets.quote, volume: self.z.vq)
        )

        self.pool.assets.base -= drained.units
        self.pool.assets.quote -= drained.value
        self.pool.volume.reset()

        return drained
    }
}
