extension Dictionary {
    @inlinable public mutating func resetUsingHint() {
        let count: Int = self.count
        self = [:]
        self.reserveCapacity(count)
    }
}
