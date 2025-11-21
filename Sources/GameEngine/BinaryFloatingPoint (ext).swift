extension BinaryFloatingPoint {
    func mix(_ a: Self, _ b: Self) -> Self {
        self * a + (1 - self) * b
    }
}
