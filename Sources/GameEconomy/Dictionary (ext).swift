extension Dictionary {
    @inlinable public mutating func resetUsingHint() {
        let count: Int = self.count
        self = [:]
        if  count > 0 {
            self.reserveCapacity(count + (count >> 2) + 3)
        }
    }
}
