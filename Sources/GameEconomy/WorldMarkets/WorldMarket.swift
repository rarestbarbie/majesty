import DequeModule
import Fraction
import GameIDs
import LiquidityPool
import RealModule

@frozen public struct WorldMarket: Identifiable {
    public let id: ID
    @usableFromInline let depth: Double
    @usableFromInline let rot: Double

    @usableFromInline var history: Deque<Aggregate>
    @usableFromInline var current: Candle<Double>
    @usableFromInline var pool: LiquidityPool

    @usableFromInline var y: Interval
    @usableFromInline var z: Interval.Indicators

    @inlinable init(
        id: ID,
        depth: Double,
        rot: Double,
        history: Deque<Aggregate>,
        current: Candle<Double>,
        pool: LiquidityPool,
        y: Interval,
        z: Interval.Indicators,
    ) {
        self.id = id
        self.depth = depth
        self.rot = rot
        self.pool = pool
        self.history = history
        self.current = current
        self.y = y
        self.z = z
    }
}
extension WorldMarket {
    @inlinable public init(state: State, shape: Shape) {
        let pool: LiquidityPool = .init(
            assets: state.z.assets,
            volume: .init(),
            fee: shape.fee
        )
        self.init(
            id: state.id,
            depth: shape.depth,
            rot: shape.rot,
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
            z: .init(assets: self.pool.assets, indicators: self.z)
        )
    }
    @inlinable public var shape: Shape {
        .init(
            depth: self.depth,
            rot: self.rot,
            fee: self.pool.fee
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
        self.y = .init(assets: self.pool.assets, indicators: self.z)
    }

    mutating func advance(history: Int) -> LiquidityPool.Assets {
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

        let drained: LiquidityPool.Assets = .init(
            base: self.drain(assets: self.pool.assets.base, volume: self.z.vb),
            quote: self.drain(assets: self.pool.assets.quote, volume: self.z.vq)
        )

        self.pool.assets.base -= drained.base
        self.pool.assets.quote -= drained.quote
        self.pool.volume.reset()

        return drained
    }

    private func drain(assets: Int64, volume: Double) -> Int64 {
        let drain: Double = self.rot * (Double.init(assets) - volume * self.depth)
        let units: Int64 = max(0, min(Int64.init(drain.rounded()), assets))
        return units
    }
}
