import GameEconomy

struct StockMarkets<LEI> where LEI: Hashable {
    private var regions: [Fiat: StockMarket<LEI>]

    init() {
        self.regions = [:]
    }
}
extension StockMarkets {
    mutating func turn(by turn: (Fiat, inout StockMarket<LEI>) -> ()) {
        var i: [Fiat: StockMarket<LEI>].Index = self.regions.startIndex
        while i < self.regions.endIndex {
            let id: Fiat = self.regions.keys[i]
            turn(id, &self.regions.values[i])
            i = self.regions.index(after: i)
        }
    }

    mutating func queueRandomPurchase(buyer: LEI, value: Int64, currency: Fiat) {
        guard value > 0 else {
            return
        }
        self.regions[currency, default: .init()].queue.append(
            .init(buyer: buyer, value: value)
        )
    }
}
extension StockMarkets {
    mutating func trade(
        security: StockMarket<LEI>.Security,
        currency: Fiat
    ) {
        self.issueShares(security: security, currency: currency)
    }

    mutating func issueShares(
        security: StockMarket<LEI>.Security,
        currency: Fiat,
    ) {
        self.regions[currency, default: .init()].securities.append(security)
    }
}
