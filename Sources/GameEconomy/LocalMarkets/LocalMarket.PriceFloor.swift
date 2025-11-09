extension LocalMarket {
    @frozen public struct PriceFloor {
        public var minimum: LocalPrice
        public var type: PriceFloorType

        @inlinable public init(minimum: LocalPrice, type: PriceFloorType) {
            self.minimum = minimum
            self.type = type
        }
    }
}
