import GameEconomy

struct LocalMarketSnapshot: Differentiable {
    let id: LocalMarket.ID
    let stabilizationFundFees: Int64
    let stabilizationFund: Reservoir
    let stockpile: Reservoir
    let y: LocalMarket.Interval
    let z: LocalMarket.Interval
    let policy: LocalMarket.Policy
}
extension LocalMarketSnapshot {
    init(state: LocalMarket.State, policy: LocalMarket.Policy) {
        self.id = state.id
        self.stabilizationFundFees = state.stabilizationFundFees
        self.stabilizationFund = state.stabilizationFund
        self.stockpile = state.stockpile
        self.y = state.yesterday
        self.z = state.today
        self.policy = policy
    }
}
