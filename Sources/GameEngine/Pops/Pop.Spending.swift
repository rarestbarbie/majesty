extension Pop {
    struct Spending {
        var buybacks: Int64
        var dividend: Int64
    }
}
extension Pop.Spending {
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
extension Pop.Spending: Equatable {}
#endif
