import D

extension WorldMarket {
    @frozen public struct Shape {
        @usableFromInline let depth: Double
        public let rot: Decimal
        public let fee: Decimal
        public let feeBoundary: Double
        @usableFromInline let feeSchedule: Double

        @inlinable init(
            depth: Double,
            rot: Decimal,
            fee: Decimal,
            feeBoundary: Double,
            feeSchedule: Double
        ) {
            self.depth = depth
            self.rot = rot
            self.fee = fee
            self.feeBoundary = feeBoundary
            self.feeSchedule = feeSchedule
        }
    }
}
extension WorldMarket.Shape {
    func fee(velocity: Double) -> Double {
        let base: Double = .init(self.fee)
        if  velocity < self.feeBoundary {
            return base * (velocity / self.feeBoundary)
        } else {
            return base + (velocity - self.feeBoundary) * self.feeSchedule
        }
    }

    func drain(assets: Int64, volume: Double) -> Int64 {
        let drain: Double = Double.init(self.rot) * (Double.init(assets) - volume * self.depth)
        let units: Int64 = max(0, min(Int64.init(drain.rounded()), assets))
        return units
    }

    /// Compute the drainage rate for UI purposes.
    public func drainage(assets: Int64, volume: Double) -> Double {
        let liquidity: Double = max(1, Double.init(assets))
        return Double.init(self.rot) * min(0, self.depth * volume - liquidity) / liquidity
    }
}
