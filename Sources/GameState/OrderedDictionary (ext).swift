import OrderedCollections

extension OrderedDictionary {
    /// Removes all entries for which `predicate` returns false on the key.
    /// This is more efficient than calling `filter` when all values are retained.
    ///
    /// Returns true if any entries were removed.
    @discardableResult
    @inlinable public mutating func prune(
        unless predicate: (Key) throws -> Bool
    ) rethrows -> Bool {
        let remove: [Int] = try self.keys.indices.reduce(into: []) {
            if try !predicate(self.keys[$1]) {
                $0.append($1)
            }
        }
        return self.remove(ascending: remove)
    }

    /// Update each value in place, removing any for which `yield` returns false.
    /// This is more efficient than calling `removeValue(forKey:)` repeatedly, and has best
    /// case performance when all values are retained.
    ///
    /// Returns true if any values were removed.
    @discardableResult
    @inlinable public mutating func update(
        with yield: (_ value: inout Value) throws -> Bool
    ) rethrows -> Bool {
        let remove: [Int] = try self.values.indices.reduce(into: []) {
            if try !yield(&self.values[$1]) {
                $0.append($1)
            }
        }
        return self.remove(ascending: remove)
    }

    @inlinable mutating func remove(ascending remove: [Int]) -> Bool {
        if  remove.isEmpty {
            return false
        }
        // rebuild the dictionary, taking advantage of the fact that `remove` is sorted
        var new: Self = .init(minimumCapacity: self.count - remove.count)
        var remaining: [Int].Iterator = remove.makeIterator()
        var next: Int? = remaining.next()
        for i: Int in self.values.indices {
            if case i? = next {
                next = remaining.next()
            } else {
                new[self.keys[i]] = self.values[i]
            }
        }
        self = new
        return true
    }
}
