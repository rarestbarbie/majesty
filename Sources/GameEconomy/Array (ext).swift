extension Array {
    /// use the previous day’s counts to allocate capacity
    @inlinable public mutating func resetUsingHint() {
        /// in a wasm environment, memory growth operations (memory.grow) and reallocations are
        /// significantly more expensive than on native platforms
        let count: Int = self.count
        self = []
        self.reserveCapacity(count)
    }
}
extension [(count: Int64, value: Double)] {
    public func medianAssumingAscendingOrder() -> Double? {
        if  self.isEmpty {
            return nil
        }

        let n: Int64 = self.reduce(0) { $0 + $1.count }
        if  n <= 0 {
            return nil
        }

        let middle: (Int64?, Int64)

        if  n & 1 == 0 {
            // if `n` is even, we know it is at least two
            middle.1 = n / 2
            middle.0 = middle.1 - 1
        } else {
            middle.1 = n / 2
            middle.0 = nil
        }

        // cumulative index as we iterate
        var passed: Int64 = 0

        var before: Double? = nil
        var after: Double? = nil

        for (count, sample): (Int64, Double) in self {
            passed += count

            if  let target: Int64 = middle.0, target < passed,
                case nil = before {
                before = sample
            }
            if  case nil = after, middle.1 < passed {
                after = sample
            }

            if  case nil = middle.0 {
                //  odd `n`
                if  let after: Double = after {
                    return after
                }
            } else {
                //  even `n`
                if  let after: Double = after,
                    let before: Double = before {
                    return 0.5 * (before + after)
                }
            }
        }

        fatalError("unreachable")
    }
}
