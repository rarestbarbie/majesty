import GameEconomy

extension StockMarket {
    struct Security {
        let attraction: Double
        let asset: LEI
        let price: Fraction?

        private init(attraction: Double, asset: LEI, unchecked price: Fraction?) {
            self.attraction = attraction
            self.asset = asset
            self.price = price
        }
    }
}
extension StockMarket.Security {
    init(attraction: Double, asset: LEI, price: Fraction) {
        self.init(attraction: attraction, asset: asset, unchecked: price.n > 0 ? price : nil)
    }
}
extension StockMarket.Security {
    func quote(value: Int64) -> (quantity: Int64, cost: Int64)? {
        if  let price: Fraction = self.price {
            let quantity: Int64 = value <> (price.d %/ price.n)
            return (quantity, cost: quantity >< price)
        } else {
            return nil
        }
    }
}
