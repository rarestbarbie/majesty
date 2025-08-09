extension Collection<Int64> {
    /// Distributes funds proportionately among shareholders based on their shares.
    /// -   Parameters:
    ///     -   funds: The total amount of funds to distribute.
    /// -   Returns:
    ///     An array where each element represents the amount of funds allocated to the
    ///     corresponding shareholder.
    @inlinable public func distribute(_ funds: Int64) -> [Int64]? {
        self.distribute(funds: { _ in funds }, share: \.self)
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
        funds: (Int64) -> Int64,
        share: (Element) -> Int64
    ) -> [Int64]? {
        let shares = self.reduce(0) { $0 + share($1) }
        if  shares <= 0 {
            // If no one has shares, no one gets funds
            return nil
        }

        return self.distribute(funds(shares), shares: shares, share: share)
    }

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
        for i: Int in allocations.indices {
            guard allocated < funds else {
                break
            }
            allocations[i] += 1
            allocated += 1
        }

        return allocations
    }
}
