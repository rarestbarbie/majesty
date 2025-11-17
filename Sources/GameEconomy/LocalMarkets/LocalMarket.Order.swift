import Fraction
import GameIDs

extension LocalMarket {
    @frozen public struct Order {
        /// Nil for private entities (such as the market itself)
        public let by: LEI?
        public let type: OrderType
        public let memo: Memo?
        public let size: Int64

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
    @inlinable public var filled: Int64 { self.unitsMatched }
    @inlinable public var value: Int64 { self.valueMatched }
}
extension LocalMarket.Order {
    mutating func fill(_ side: LocalMarket.Side, price: LocalPrice, units: Int64) {
        self.unitsMatched = units

        switch (side, self.type) {
        case (.buy, .taker), (.sell, .maker):
            self.valueMatched = units >< price.value
        case (.buy, .maker), (.sell, .taker):
            self.valueMatched = units <> price.value
        }
    }
    mutating func fill(_ side: LocalMarket.Side, price: LocalPrice) {
        self.fill(side, price: price, units: self.size)
    }
}
extension LocalMarket {
    @frozen public enum OrderType {
        case maker
        case taker
    }
}
extension LocalMarket {
    enum Side {
        case buy
        case sell
    }
}
