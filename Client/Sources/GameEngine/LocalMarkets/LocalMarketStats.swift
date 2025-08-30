struct LocalMarketStats {
    var price: Int64
    var supply: Int64
    var demand: Int64

    init(price: Int64, supply: Int64 = 0, demand: Int64 = 0) {
        self.price = price
        self.supply = supply
        self.demand = demand
    }
}
