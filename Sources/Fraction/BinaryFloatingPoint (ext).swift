extension BinaryFloatingPoint {
    @inlinable public init(_ fraction: Fraction) {
        self = Self.init(fraction.n) / Self.init(fraction.d)
    }
}
