extension StockPrice {
    struct Quote {
        let quantity: Int64
        let value: Int64
    }
}
extension StockPrice.Quote {
    static var zero: Self { .init(quantity: 0, value: 0) }
}
