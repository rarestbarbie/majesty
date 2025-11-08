extension LocalMarket {
    @frozen public struct PriceFloor {
        public var minimum: LocalPrice
        public var type: PriceFloorType
    }
}
