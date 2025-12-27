import LiquidityPool
import RealModule

extension LiquidityPool.Assets {
    @inlinable public var liquidity: Double {
        .sqrt(Double.init(self.quote) * Double.init(self.base))
    }
}
