import Fraction

enum FactoryBudget {
    case constructing(OperatingBudget)
    case liquidating(Liquidating)
    case active(OperatingBudget)
}
extension FactoryBudget {
    static func liquidating(
        state: Factory,
        sharePrice: Fraction
    ) -> Self {
        let balance: Int64 = state.inventory.account.balance
        return .liquidating(
            .init(buybacks: min(balance, max(balance / 100, sharePrice.roundedUp)))
        )
    }
}
