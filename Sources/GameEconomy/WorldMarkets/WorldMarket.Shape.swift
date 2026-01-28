import Fraction

extension WorldMarket {
    @frozen public struct Shape {
        public let depth: Double
        public let rot: Double
        @usableFromInline let fee: Fraction

        @inlinable init(
            depth: Double,
            rot: Double,
            fee: Fraction
        ) {
            self.depth = depth
            self.rot = rot
            self.fee = fee
        }
    }
}
