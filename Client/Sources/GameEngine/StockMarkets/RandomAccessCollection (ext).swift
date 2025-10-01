extension RandomAccessCollection {
    /// Returns the index of the first element in the collection for which the
    /// given predicate is `false`.
    ///
    /// If there is no such element, the collection’s `endIndex` is returned.
    /// The collection must be partitioned by the predicate.
    ///
    /// - Complexity: O(log n), where n is the number of elements in the collection.
    func partitioningIndex(where predicate: (Element) throws -> Bool) rethrows -> Index {
        var low: Index = self.startIndex
        var high: Index = self.endIndex

        while low != high {
            let mid: Index = self.index(low, offsetBy: self.distance(from: low, to: high) / 2)
            if try predicate(self[mid]) {
                low = self.index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}
