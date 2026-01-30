extension Building {
    struct Spending {
        var buybacks: Int64
        var dividend: Int64
    }
}
extension Building.Spending: AccountingCashFlow {
    var salaries: Int64 { 0 }
    var wages: Int64 { 0 }
}
extension Building.Spending {
    static var zero: Self {
        .init(
            buybacks: 0,
            dividend: 0,
        )
    }
}

#if TESTABLE
extension Building.Spending: Equatable {}
#endif
