import Fraction

@frozen public struct ResourceBudgetTier {
    public var tradeable: Int64
    public var inelastic: Int64

    @inlinable public init(tradeable: Int64 = 0, inelastic: Int64 = 0) {
        self.tradeable = tradeable
        self.inelastic = inelastic
    }
}
extension ResourceBudgetTier {
    @inlinable public var total: Int64 { self.tradeable + self.inelastic }
}
extension ResourceBudgetTier {
    public mutating func distribute(
        funds available: Int64,
        inelastic: Int64,
        tradeable: Int64,
    ) {
        guard available > 0 else {
            return
        }

        if let item: [Int64] = [tradeable, inelastic].distribute(available) {
            self.tradeable += item[0]
            self.inelastic += item[1]
        }
    }
    public mutating func distribute(
        funds available: Int64,
        inelastic: Int64,
        tradeable: Int64,
        w: Int64,
        c: Int64,
    ) -> (w: Int64, c: Int64)? {
        guard available > 0 else {
            return nil
        }

        if let item: [Int64] = [tradeable, inelastic, w, c].distribute(available) {
            self.tradeable += item[0]
            self.inelastic += item[1]
            return (w: item[2], c: item[3])
        } else {
            return nil
        }
    }
}
