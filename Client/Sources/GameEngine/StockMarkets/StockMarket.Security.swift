import GameEconomy

extension StockMarket {
    struct Security {
        let asset: LegalEntity
        let price: Fraction

        private init(asset: LegalEntity, unchecked price: Fraction) {
            self.asset = asset
            self.price = price
        }
    }
}
extension StockMarket.Security {
    init?(asset: LegalEntity, price: Fraction) {
        guard price.n > 0 else {
            return nil
        }

        self.init(asset: asset, unchecked: price)
    }
}
extension StockMarket.Security {
    func quote(value: Int64) -> (quantity: Int64, cost: Int64) {
        let quantity: Int64 = value <> (self.price.d %/ self.price.n)
        return (quantity, cost: quantity >< self.price)
    }
}
