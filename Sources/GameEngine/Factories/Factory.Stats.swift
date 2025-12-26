import Assert

extension Factory {
    struct Stats {
        private(set) var productivity: Int64
        private(set) var cashFlow: CashFlowStatement
        private(set) var profit: ProfitMargins
    }
}
extension Factory.Stats {
    init() {
        self.init(productivity: 0, cashFlow: .init(), profit: .undefined)
    }
}
extension Factory.Stats {
    mutating func update(from state: Factory, in region: RegionalProperties) {
        self.productivity = region.modifiers.factoryProductivity[state.type]?.value ?? 1

        self.cashFlow.reset()
        self.cashFlow.update(with: state.inventory.l)
        self.cashFlow.update(with: state.inventory.e)
        self.cashFlow[.workers] = state.spending.wages
        self.cashFlow[.clerks] = state.spending.salaries

        self.profit = .compute(factory: state)
    }
}
