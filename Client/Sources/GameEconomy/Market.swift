import DequeModule

@frozen public struct Market: Identifiable {
    public let id: Market.AssetPair
    public var pool: LiquidityPool
    public var history: Deque<Candle<Double>>
    public var current: Candle<Double>

    @inlinable public init(
        id: Market.AssetPair,
        pool: LiquidityPool = .init(liq: (2, 2)),
        history: Deque<Candle<Double>> = []
    ) {
        self.id = id
        self.pool = pool
        self.history = history
        self.current = .open(Double.init(self.pool.ratio))
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
            self.current.update(Double.init(self.pool.ratio))
        }
    }

    /// Unlike `pool.conjugated`, this property updates the candle on mutation.
    var conjugate: LiquidityPool {
        _read {
            yield self.pool.conjugated
        }
        _modify {
            yield &self.pool.conjugated
            self.current.update(Double.init(self.pool.ratio))
        }
    }
}
extension Market {
    @inlinable public mutating func turn(history: Int) {
        if  self.history.count >= history {
            self.history.removeFirst(self.history.count - history + 1)
        }
        self.history.append(self.current)
        self.current = .open(Double.init(self.pool.ratio))
    }
}
