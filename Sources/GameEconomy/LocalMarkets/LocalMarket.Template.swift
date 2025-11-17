extension LocalMarket {
    @frozen public struct Template {
        public let storage: Bool
        public let limit: (
            min: LocalPriceLevel?,
            max: LocalPriceLevel?
        )

        @inlinable public init(
            storage: Bool,
            limit: (
                min: LocalPriceLevel?,
                max: LocalPriceLevel?
            )
        ) {
            self.storage = storage
            self.limit = limit
        }
    }
}
extension LocalMarket.Template {
    @inlinable public static var `default`: Self {
        .init(storage: false, limit: (nil, nil))
    }
}
