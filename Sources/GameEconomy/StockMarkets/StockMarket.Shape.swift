extension StockMarket {
    @frozen public struct Shape {
        /// Real interest rate
        public let r: Double

        @inlinable public init(r: Double) {
            self.r = r
        }
    }
}
