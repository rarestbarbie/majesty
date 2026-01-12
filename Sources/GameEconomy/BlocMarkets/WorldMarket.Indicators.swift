import LiquidityPool
import RealModule

extension WorldMarket {
    @frozen public struct Indicators {
        /// Square root of quote volume times base volume.
        public var v: Double
        public var vb: Double
        public var vq: Double

        @inlinable public init(
            v: Double,
            vb: Double,
            vq: Double
        ) {
            self.v = v
            self.vb = vb
            self.vq = vq
        }
    }
}
extension WorldMarket.Indicators {
    @inlinable static var ema: Double { 0.01 }
}
extension WorldMarket.Indicators {
    @inlinable static var zero: Self {
        .init(v: 0, vb: 0, vq: 0)
    }

    @inlinable static func compute(from _: LiquidityPool.Assets) -> Self {
        .zero
    }

    @inlinable mutating func update(from pool: LiquidityPool) {
        let vb: Double = .init(pool.volume.base.total)
        let vq: Double = .init(pool.volume.quote.total)
        let v: Double = .sqrt(vb * vq)

        self.vb = Self.ema.mix(self.vb, vb)
        self.vq = Self.ema.mix(self.vq, vq)
        self.v = Self.ema.mix(self.v, v)
    }
}
