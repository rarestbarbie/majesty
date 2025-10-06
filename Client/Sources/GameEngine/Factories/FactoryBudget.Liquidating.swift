extension FactoryBudget {
    struct Liquidating {
        var buybacks: Int64

        init(
            buybacks: Int64 = 0,
        ) {
            self.buybacks = buybacks
        }
    }
}
