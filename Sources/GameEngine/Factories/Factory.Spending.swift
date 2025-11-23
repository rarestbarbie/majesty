extension Factory {
    struct Spending {
        var buybacks: Int64
        var dividend: Int64
        var salaries: Int64
        var wages: Int64
    }
}
extension Factory.Spending {
    static var zero: Self {
        .init(
            buybacks: 0,
            dividend: 0,
            salaries: 0,
            wages: 0,
        )
    }

    var totalExcludingEquityPurchases: Int64 {
        self.dividend + self.salaries + self.wages
    }
}

#if TESTABLE
extension Factory.Spending: Equatable, Hashable {}
#endif
