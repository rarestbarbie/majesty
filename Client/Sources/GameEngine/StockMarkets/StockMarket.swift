import GameEconomy
import Random

struct StockMarket<LEI> where LEI: Hashable {
    var queue: [RandomPurchase]
    var securities: [Security]

    init() {
        self.queue = []
        self.securities = []
    }
}
extension StockMarket {
    mutating func match(using random: inout PseudoRandom) -> [Fill] {
        defer {
            self.queue.removeAll(keepingCapacity: true)
            self.securities.removeAll(keepingCapacity: true)
        }

        guard
        let sampler: RandomWeightedSampler<Security, Double> = .init(
            choices: self.securities,
            sampleWeight: \.attraction
        ) else {
            return []
        }

        return self.queue.map {
            /// Will always be non-nil because of the `isEmpty` check above.
            let security: Security = sampler.next(using: &random.generator)

            let quantity: Int64
            let cost: Int64

            if  let quote: (quantity: Int64, cost: Int64) = security.quote(value: $0.value) {
                quantity = quote.quantity
                cost = quote.cost
            } else {
                // target an initial share price of 10.00
                cost = $0.value
                quantity = max(1, cost / 10)
            }
            return .init(
                asset: security.asset,
                buyer: $0.buyer,
                quantity: quantity,
                cost: cost
            )
        }
    }
}
