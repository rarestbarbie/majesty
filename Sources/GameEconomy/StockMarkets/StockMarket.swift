import Assert
import GameIDs
import Random

@frozen public struct StockMarket {
    public let id: CurrencyID
    @usableFromInline var buyers: [RandomPurchase]
    @usableFromInline var assets: [TradeableAsset]

    @inlinable init(id: CurrencyID) {
        self.id = id
        self.buyers = []
        self.assets = []
    }
}
extension StockMarket {
    public mutating func match(
        shape: Shape,
        random: inout PseudoRandom,
        execute: (inout PseudoRandom, CurrencyID, StockMarket.Fill) -> ()
    ) {
        defer {
            self.buyers.removeAll(keepingCapacity: true)
            self.assets.removeAll(keepingCapacity: true)
        }

        guard
        let sampler: RandomWeightedSampler<[TradeableAsset], Double> = .init(
            choices: self.assets,
            sampleWeight: { $0.security.attraction(r: shape.r) }
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

            execute(&random, self.id, fill)
        }
    }
}
