extension Building {
    struct Spending {
        var buybacks: Int64
        var dividend: Int64
    }
}
extension Building.Spending {
    static var zero: Self {
        .init(
            buybacks: 0,
            dividend: 0,
        )
    }

    var totalExcludingEquityPurchases: Int64 {
        self.dividend
    }
}

#if TESTABLE
extension Building.Spending: Equatable, Hashable {}
#endif
