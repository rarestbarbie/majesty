import Fraction

extension Factory {
    enum Budget {
        case constructing(OperatingBudget)
        case active(OperatingBudget)
        case liquidating(LiquidationBudget)
    }
}
extension Factory.Budget {
    static func liquidating(
        account: Bank.Account,
        sharePrice: Fraction
    ) -> Self {
        let balance: Int64 = account.balance
        return .liquidating(
            .init(buybacks: min(balance, max(balance / 100, sharePrice.roundedUp)))
        )
    }
}
#if TESTABLE
extension Factory.Budget: Equatable, Hashable {}
#endif
