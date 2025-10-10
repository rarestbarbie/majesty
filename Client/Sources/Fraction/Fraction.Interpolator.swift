extension Fraction {
    @frozen public struct Interpolator<Float> where Float: BinaryFloatingPoint {
        @usableFromInline let f: Float
        @usableFromInline let g: Float

        @inlinable public init(_ fraction: Fraction) {
            self.f = .init(fraction)
            self.g = 1 - self.f
        }
    }
}
extension Fraction.Interpolator {
    @inlinable public func mix(_ a: Float, _ b: Float) -> Float {
        self.f * a + self.g * b
    }
}
