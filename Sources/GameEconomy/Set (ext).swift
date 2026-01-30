extension Set {
    @inlinable public mutating func resetExpectingCopy() {
        let count: Int = self.count
        self = []
        if  count > 0 {
            self.reserveCapacity(count + (count >> 2) + 3)
        }
    }
    @inlinable public mutating func resetUsingHint() {
        // todo: benchmark smarter heuristics
        self.removeAll(keepingCapacity: true)
    }
}
