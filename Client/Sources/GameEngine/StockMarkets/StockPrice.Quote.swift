extension StockPrice {
    struct Quote {
        var quantity: Int64
        var value: Int64
    }
}
extension StockPrice.Quote {
    static var zero: Self { .init(quantity: 0, value: 0) }
}
