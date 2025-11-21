@frozen public struct Currency: Identifiable {
    public let id: CurrencyID
    public let name: String
    public let long: String

    @inlinable public init(
        id: CurrencyID,
        name: String,
        long: String
    ) {
        self.id = id
        self.name = name
        self.long = long
    }
}
