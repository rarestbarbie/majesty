extension Equity {
    struct Statistics {
        var owners: [(id: Owner, shares: Int64)]
        var shares: EquityShares
    }
}
extension Equity.Statistics {
    init() {
        self.init(owners: [], shares: .init(outstanding: 0, bought: 0, issued: 0))
    }
}
extension Equity.Statistics {
    static func compute(from equity: Equity<Owner>) -> Self {
        let shares: (outstanding: Int64, bought: Int64, issued: Int64) = equity.shares.reduce(
            into: (0, 0, 0)
        ) {
            $0.outstanding += $1.value.shares
            $0.issued += $1.value.bought
            // Buybacks are currently the only way pops can dispose of shares
            $0.bought += $1.value.sold
        }

        return .init(
            owners: equity.shares.values.map { ($0.id, $0.shares) },
            shares: .init(
                outstanding: shares.outstanding,
                bought: shares.bought,
                issued: shares.issued
            )
        )
    }
}
