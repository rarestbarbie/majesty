extension BinaryFloatingPoint {
    @inlinable public func mix(_ a: Self, _ b: Self) -> Self {
        (1 - self) * a + self * b
    }
}
