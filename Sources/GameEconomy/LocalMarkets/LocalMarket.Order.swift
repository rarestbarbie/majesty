import Fraction
import GameIDs

extension LocalMarket {
    @frozen @usableFromInline struct Order {
        /// Nil for private entities (such as the market itself)
        @usableFromInline let by: LEI?
        @usableFromInline let type: OrderType
        @usableFromInline let memo: Memo?
        @usableFromInline let size: Int64

        @usableFromInline var unitsMatched: Int64
        @usableFromInline var valueMatched: Int64


        init(by: LEI?, type: OrderType, memo: Memo?, size: Int64, unitsMatched: Int64 = 0, valueMatched: Int64 = 0) {
            self.by = by
            self.type = type
            self.memo = memo
            self.size = size
            self.unitsMatched = unitsMatched
            self.valueMatched = valueMatched
        }
    }
}
extension LocalMarket.Order {
    mutating func fill(_ side: LocalMarket.Side, price: (bid: LocalPrice, ask: LocalPrice), units: Int64) {
        self.unitsMatched = units

        switch (side, self.type) {
        case (.buy, .taker), (.sell, .maker):
            self.valueMatched = units >< price.ask.value
        case (.buy, .maker), (.sell, .taker):
            self.valueMatched = units <> price.bid.value
        }
    }
    mutating func fill(_ side: LocalMarket.Side, price: (bid: LocalPrice, ask: LocalPrice)) {
        self.fill(side, price: price, units: self.size)
    }
}
