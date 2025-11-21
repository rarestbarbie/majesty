import GameIDs
import RealModule

extension StockMarket {
    @frozen public struct Security {
        public let id: LEI
        public let stockPrice: StockPrice?
        public let profitability: Double

        @inlinable public init(
            id: LEI,
            stockPrice: StockPrice?,
            profitability: Double
        ) {
            self.id = id
            self.stockPrice = stockPrice
            self.profitability = profitability
        }
    }
}
extension StockMarket.Security {
    func attraction(r: Double) -> Double {
        // scale profitability to range `0 ... 1`
        let p: Double = (self.profitability + 1) * 0.5
        // higher real interest rates bias investment away from unprofitable assets
        return .pow(p, 1 + 100 * r)
    }
}
