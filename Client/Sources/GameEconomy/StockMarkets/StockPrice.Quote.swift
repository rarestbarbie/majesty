extension StockPrice {
    @frozen public struct Quote {
        public var quantity: Int64
        public var value: Int64

        @inlinable public init(quantity: Int64, value: Int64) {
            self.quantity = quantity
            self.value = value
        }
    }
}
extension StockPrice.Quote {
    @inlinable public static var zero: Self { .init(quantity: 0, value: 0) }
}
