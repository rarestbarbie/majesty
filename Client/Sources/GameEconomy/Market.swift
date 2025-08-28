import DequeModule

@frozen public struct Market: Identifiable {
    public let id: Market.AssetPair
    public var pool: LiquidityPool
    public var history: Deque<Interval>
    public var current: Candle<Double>

    @inlinable public init(
        id: Market.AssetPair,
        pool: LiquidityPool = .init(assets: .init(base: 2, quote: 2)),
        history: Deque<Interval> = []
    ) {
        self.id = id
        self.pool = pool
        self.history = history
        self.current = .open(self.pool.price)
    }
}
extension Market {
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
extension Market {
    @inlinable public mutating func turn(history: Int) {
        if  self.history.count >= history {
            self.history.removeFirst(self.history.count - history + 1)
        }

        let interval: Interval = .init(
            prices: self.current,
            volume: self.pool.volume.base.i + self.pool.volume.base.o
        )

        self.current = .open(self.pool.price)
        self.pool.volume.reset()

        self.history.append(interval)
    }
}
