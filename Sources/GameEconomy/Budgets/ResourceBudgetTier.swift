import Fraction

@frozen public struct ResourceBudgetTier {
    public var segmented: Int64
    public var tradeable: Int64

    @inlinable public init(segmented: Int64 = 0, tradeable: Int64 = 0) {
        self.segmented = segmented
        self.tradeable = tradeable
    }
}
extension ResourceBudgetTier {
    @inlinable public var total: Int64 { self.tradeable + self.segmented }
}
extension ResourceBudgetTier {
    public mutating func distribute(
        funds available: Int64,
        segmented: Int64,
        tradeable: Int64,
    ) {
        guard available > 0 else {
            return
        }

        let items: [Int64]? = [tradeable, segmented].distribute(share: \.self) {
            min($0, available)
        }

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
        }
    }
    public mutating func distribute(
        funds available: Int64,
        segmented: Int64,
        tradeable: Int64,
        w: Int64,
        c: Int64,
    ) -> (w: Int64, c: Int64)? {
        guard available > 0 else {
            return nil
        }

        let items: [Int64]? = [tradeable, segmented, w, c].distribute(share: \.self) {
            min($0, available)
        }

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
            return (w: items[2], c: items[3])
        } else {
            return nil
        }
    }
}
