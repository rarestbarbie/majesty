import LiquidityPool
import RealModule

extension WorldMarket {
    @frozen public struct Interval {
        public let assets: LiquidityPool.Assets
        /// Square root of quote volume times base volume.
        public let v: Double
        public let vb: Double
        public let vq: Double

        @inlinable public init(
            assets: LiquidityPool.Assets,
            v: Double,
            vb: Double,
            vq: Double
        ) {
            self.assets = assets
            self.v = v
            self.vb = vb
            self.vq = vq
        }
    }
}
extension WorldMarket.Interval {
    @inlinable init(
        assets: LiquidityPool.Assets,
        indicators: Indicators
    ) {
        self.init(
            assets: assets,
            v: indicators.v,
            vb: indicators.vb,
            vq: indicators.vq
        )
    }

    @inlinable var indicators: Indicators {
        .init(v: self.v, vb: self.vb, vq: self.vq)
    }
}
extension WorldMarket.Interval {
    @inlinable public var velocity: Double {
        let liquidity: Double = self.assets.liquidity
        return liquidity > 0 ? min(self.v / liquidity, 1) : 1
    }
}
