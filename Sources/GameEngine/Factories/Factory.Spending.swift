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
}

#if TESTABLE
extension Factory.Spending: Equatable, Hashable {}
#endif
