extension LocalMarket {
    @frozen public struct Shape {
        /// Units of days, must be greater than 2!
        public let storage: Int64?
        public let limit: (
            min: LocalPriceLevel?,
            max: LocalPriceLevel?
        )

        @inlinable public init(
            storage: Int64?,
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
extension LocalMarket.Shape {
    @inlinable public static var `default`: Self {
        .init(storage: nil, limit: (nil, nil))
    }
}
