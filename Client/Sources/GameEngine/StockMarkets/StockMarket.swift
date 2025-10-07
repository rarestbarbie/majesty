import GameEconomy
import GameState
import Random

struct StockMarket {
    var buyers: [RandomPurchase]
    var assets: [TradeableAsset]

    init() {
        self.buyers = []
        self.assets = []
    }
}
extension StockMarket {
    struct TradeableAsset {
        let security: Security
        var issuable: Int64
    }
}
extension StockMarket {
    mutating func match(
        random: inout PseudoRandom,
        execute: (inout PseudoRandom, StockMarket.Fill) -> ()
    ) {
        defer {
            self.buyers.removeAll(keepingCapacity: true)
            self.assets.removeAll(keepingCapacity: true)
        }

        guard
        let sampler: RandomWeightedSampler<[TradeableAsset], Double> = .init(
            choices: self.assets,
            sampleWeight: \.security.attraction
        ) else {
            return
        }

        for bid: RandomPurchase in self.buyers {
            let fill: Fill = {
                let issued: StockPrice.Quote
                let market: StockPrice.Quote

                if  let stockPrice: StockPrice = $0.security.stockPrice {
                    let quantity: Int64 = stockPrice.quantity(value: bid.value)
                    if  quantity < $0.issuable {
                        issued = stockPrice.quote(quantity: quantity)
                        market = .zero
                    } else {
                        issued = stockPrice.quote(quantity: $0.issuable)
                        market = stockPrice.quote(quantity: quantity - $0.issuable)
                    }
                } else {
                    // target an initial share price of 10.00
                    let quantity: Int64 = min(bid.value / 10, $0.issuable)
                    issued = .init(quantity: quantity, value: quantity * 10)
                    market = .zero
                }

                $0.issuable -= issued.quantity

                return .init(
                    asset: $0.security.id,
                    buyer: bid.buyer,
                    issued: issued,
                    market: market,
                )
            } (&self.assets[sampler.next(using: &random.generator)])

            execute(&random, fill)
        }
    }
}
