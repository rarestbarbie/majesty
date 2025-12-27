extension Collection<Int64> {
    /// Distributes funds proportionately among shareholders based on their shares.
    /// -   Parameters:
    ///     -   funds: The total amount of funds to distribute.
    /// -   Returns:
    ///     An array where each element represents the amount of funds allocated to the
    ///     corresponding shareholder.
    @inlinable public func distribute(_ funds: Int64) -> [Int64]? {
        // can’t use `\.self`, the compiler forgets to optimize it
        self.distribute(funds) { $0 }
    }
}
extension Collection<Double> {
    @inlinable public func distribute(_ funds: Int64) -> [Int64]? {
        self.distribute(funds) { $0 }
    }
}
extension Collection {
    @inlinable public func distribute(_ funds: Int64, share: (Element) -> Int64) -> [Int64]? {
        self.distribute(share: share) { _ in funds }
    }
    @inlinable public func distribute(
        _ funds: Int64,
        share: (Element) -> Double
    ) -> [Int64]? {
        self.distribute(share: share) { _ in funds }
    }
}
extension Collection {
    @inlinable public func split(limit: Int64, share: (Element) -> Int64) -> [Int64]? {
        // TODO: optimization opportunity here where the sum of shares is under the limit?
        self.distribute(share: share) { Swift.min($0, limit) }
    }
}
extension Collection {
    /// Distributes funds proportionately among shareholders based on their holdings.
    ///
    /// -   Parameters:
    ///     -   funds:
    ///         A closure that receives the total shares in the collection and returns the total
    ///         amount of funds to distribute.
    ///     -   share:
    ///         A closure that receives an element of the collection and returns the number of
    ///         shares held by that element.
    ///
    /// -   Returns:
    ///     An array where each element represents the amount of funds allocated to the
    ///     corresponding shareholder.
    @inlinable public func distribute(
        share: (Element) -> Int64,
        funds: (Int64) -> Int64,
    ) -> [Int64]? {
        let shares: Int64 = self.reduce(0) { $0 + share($1) }
        if  shares <= 0 {
            // If no one has shares, no one gets funds
            return nil
        }

        return self.distribute(funds(shares), shares: shares, share: share)
    }

    /// Distributes funds proportionately among shareholders based on their holdings,
    /// using floating-point weights.
    @inlinable func distribute(
        share: (Element) -> Double,
        funds: (Double) -> Int64,
    ) -> [Int64]? {
        let shares: Double = self.reduce(0) { $0 + share($1) }
        if shares <= 0 {
            return nil
        }

        return self.distribute(funds(shares), shares: shares, share: share)
    }
}
extension Collection {
    @inlinable func distribute(
        _ funds: Int64,
        shares: Int64,
        share: (Element) -> Int64
    ) -> [Int64] {
        // Initialize allocation array
        var allocations: [Int64] = .init(repeating: 0, count: self.count)
        var allocated: Int64 = 0

        // First pass: calculate the floor of proportional distribution
        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            let numerator: (Int64, UInt64) = funds.multipliedFullWidth(by: share(element))
            let (amount, _): (Int64, Int64) = shares.dividingFullWidth(numerator)
            allocations[i] = amount
            allocated += amount
        }

        // Second pass: distribute remaining funds to earlier shareholders
        // who have a non-zero share
        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            guard allocated < funds else {
                break
            }

            guard share(element) > 0 else {
                continue
            }

            allocations[i] += 1
            allocated += 1
        }

        return allocations
    }

    @inlinable func distribute(
        _ funds: Int64,
        shares: Double,
        share: (Element) -> Double
    ) -> [Int64] {
        // Initialize allocation array
        var allocations: [Int64] = .init(repeating: 0, count: self.count)
        var allocated: Int64 = 0
        let dividend: Double = .init(funds)

        // First pass: calculate the floor of proportional distribution
        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            let amount: Int64 = .init(dividend * share(element) / shares)
            allocations[i] = amount
            allocated += amount
        }

        // Second pass: distribute remaining funds to earlier shareholders
        for (i, element): (Int, Element) in zip(allocations.indices, self) {
            guard allocated < funds else {
                break
            }
            guard share(element) > 0 else {
                continue
            }
            allocations[i] += 1
            allocated += 1
        }

        return allocations
    }
}
