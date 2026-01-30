extension Set {
    @inlinable public mutating func resetUsingHint() {
        let count: Int = self.count
        self = []
        self.reserveCapacity(count)
    }
}
