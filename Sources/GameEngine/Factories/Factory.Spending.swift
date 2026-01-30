extension Factory {
    struct Spending: AccountingCashFlow {
        var buybacks: Int64
        var dividend: Int64
        var salariesUsed: Int64
        /// used for profit calculation only
        var salariesIdle: Int64
        var wages: Int64

        /// open clerk positions
        var oc: Int64
        /// open worker positions
        var ow: Int64
    }
}
extension Factory.Spending {
    static var zero: Self {
        .init(
            buybacks: 0,
            dividend: 0,
            salariesUsed: 0,
            salariesIdle: 0,
            wages: 0,
            oc: 0,
            ow: 0
        )
    }

    var salaries: Int64 { self.salariesUsed + self.salariesIdle }
}

#if TESTABLE
extension Factory.Spending: Equatable {}
#endif
