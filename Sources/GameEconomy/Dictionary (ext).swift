extension Dictionary {
    @inlinable public mutating func resetExpectingCopy() {
        let count: Int = self.count
        self = [:]
        self.reserveCapacity(count)
    }
    @inlinable public mutating func resetUsingHint() {
        // todo: benchmark smarter heuristics
        self.removeAll(keepingCapacity: true)
    }
}
