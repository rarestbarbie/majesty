import GameEconomy
import Random

struct StockMarket<LegalEntity> where LegalEntity: Hashable {
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
        if  self.securities.isEmpty {
            return []
        }
        return self.queue.map {
            /// Will always be non-nil because of the `isEmpty` check above.
            let security: Security = securities.randomElement(using: &random.generator)!
            let quote: (quantity: Int64, cost: Int64) = security.quote(value: $0.value)
            return .init(
                asset: security.asset,
                buyer: $0.buyer,
                quantity: quote.quantity,
                cost: quote.cost
            )
        }
    }
}
