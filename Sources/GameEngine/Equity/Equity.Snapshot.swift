import Fraction

extension Equity {
    struct Snapshot where Owner: Sendable {
        let sharePrice: Fraction
        let shareCount: Int64
        let owners: [Statistics.Shareholder]

        let traded: Int64
        let issued: Int64
        let splits: Int
        let splitLast: EquitySplit?
    }
}
extension Equity.Snapshot {
    init(equity: borrowing Equity<Owner>, stats: Equity<Owner>.Statistics) {
        self.sharePrice = stats.sharePrice
        self.shareCount = stats.shareCount
        self.owners = stats.owners

        self.traded = equity.traded
        self.issued = equity.issued
        self.splits = equity.splits.count
        self.splitLast = equity.splits.last
    }
}
