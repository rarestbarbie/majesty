import Fraction
import GameUI

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
extension Equity.Snapshot {
    func aggregate(
        where predicate: (Equity<Owner>.Statistics.Shareholder) -> Bool
    ) -> Ratio<Int64> {
        self.owners.reduce(into: .zero) {
            if  predicate($1) {
                $0.selected += $1.shares
            }
            $0.total += $1.shares
        }
    }
}
