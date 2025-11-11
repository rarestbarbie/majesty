@frozen public struct LocalPriceLevel {
    public var price: LocalPrice
    public var label: LocalPriceLevelType

    @inlinable public init(price: LocalPrice, label: LocalPriceLevelType) {
        self.price = price
        self.label = label
    }
}
