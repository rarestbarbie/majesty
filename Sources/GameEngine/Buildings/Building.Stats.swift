import Assert

extension Building {
    struct Stats {
        private(set) var utilization: Double
        private(set) var cashFlow: CashFlowStatement
        private(set) var profit: ProfitMargins
    }
}
extension Building.Stats {
    init() {
        self.init(utilization: 0, cashFlow: .init(), profit: .undefined)
    }
}
extension Building.Stats {
    mutating func update(from state: Building) {
        if  let utilization: Double = state.inventory.out.utilization {
            self.utilization = utilization
        } else {
            self.utilization = 1
        }

        #assert(0 ... 1 ~= self.utilization, "Utilization must be between 0 and 1")

        self.cashFlow.reset()
        self.cashFlow.update(with: state.inventory.l)
        self.cashFlow.update(with: state.inventory.e)

        self.profit = .compute(asset: state)
    }
}
