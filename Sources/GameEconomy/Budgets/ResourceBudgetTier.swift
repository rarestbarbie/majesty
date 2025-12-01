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
    public mutating func distributeAsConsumer(
        funds available: Int64,
        segmented: Int64,
        tradeable: Int64,
    ) {
        guard available > 0 else {
            return
        }

        let totalCost: Int64 = tradeable + segmented
        let items: [Int64]? = [
            Double.sqrt(Double.init(tradeable)),
            Double.sqrt(Double.init(segmented))
        ].distribute(min(totalCost, available))

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
        }
    }
    public mutating func distributeAsBusiness(
        funds available: Int64,
        segmented: Double,
        tradeable: Double,
    ) {
        guard available > 0 else {
            return
        }

        let totalCost: Int64 = .init((tradeable + segmented).rounded(.up))
        let items: [Int64]? = [
            tradeable,
            segmented
        ].distribute(min(totalCost, available))

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
        }
    }
    public mutating func distributeAsBusiness(
        funds available: Int64,
        segmented: Double,
        tradeable: Double,
        w: Double,
    ) -> Int64? {
        guard available > 0 else {
            return nil
        }

        let totalCost: Int64 = .init((tradeable + segmented + w).rounded(.up))
        let items: [Int64]? = [
            tradeable,
            segmented,
            w
        ].distribute(min(totalCost, available))

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
            return items[2]
        } else {
            return nil
        }
    }
    public mutating func distributeAsBusiness(
        funds available: Int64,
        segmented: Int64,
        tradeable: Int64,
    ) {
        guard available > 0 else {
            return
        }

        // closure instead of keypath, to avoid compiler optimization issues
        let items: [Int64]? = [tradeable, segmented].distribute(share: { $0 }) {
            min($0, available)
        }

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
        }
    }
    public mutating func distributeAsBusiness(
        funds available: Int64,
        segmented: Int64,
        tradeable: Int64,
        w: Int64,
    ) -> Int64? {
        guard available > 0 else {
            return nil
        }

        // closure instead of keypath, to avoid compiler optimization issues
        let items: [Int64]? = [tradeable, segmented, w].distribute(share: { $0 }) {
            min($0, available)
        }

        if  let items: [Int64] {
            self.tradeable += items[0]
            self.segmented += items[1]
            return items[2]
        } else {
            return nil
        }
    }
}
#if TESTABLE
extension ResourceBudgetTier: Equatable, Hashable {}
#endif
