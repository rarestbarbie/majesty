import GameEconomy

extension StockMarket {
    struct Security {
        let attraction: Double
        let asset: LegalEntity
        let price: Fraction

        private init(attraction: Double, asset: LegalEntity, unchecked price: Fraction) {
            self.attraction = attraction
            self.asset = asset
            self.price = price
        }
    }
}
extension StockMarket.Security {
    init?(attraction: Double, asset: LegalEntity, price: Fraction) {
        guard price.n > 0 else {
            return nil
        }

        self.init(attraction: attraction, asset: asset, unchecked: price)
    }
}
extension StockMarket.Security {
    func quote(value: Int64) -> (quantity: Int64, cost: Int64) {
        let quantity: Int64 = value <> (self.price.d %/ self.price.n)
        return (quantity, cost: quantity >< self.price)
    }
}
