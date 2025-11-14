extension Pop {
    struct Stats {
        private(set) var employmentBeforeEgress: Double
        private(set) var employedBeforeEgress: Int64
        private(set) var cashFlow: CashFlowStatement
    }
}
extension Pop.Stats {
    init() {
        self.init(
            employmentBeforeEgress: 0,
            employedBeforeEgress: 0,
            cashFlow: .init()
        )
    }
}
extension Pop.Stats {
    mutating func update(from state: Pop) {
        self.employedBeforeEgress = state.employed()

        if  state.inventory.out.inelastic.isEmpty {
            self.employmentBeforeEgress = Double.init(
                self.employedBeforeEgress
            ) / Double.init(
                state.z.size
            )
        } else {
            self.employmentBeforeEgress = state.inventory.out.inelastic.values.reduce(0) {
                let sold: Double = $1.units.added > 0
                    ? Double.init($1.unitsSold) / Double.init($1.units.added)
                    : 1

                return max($0, sold)
            }
        }

        self.cashFlow.reset()
        self.cashFlow.update(with: state.inventory.l)
        self.cashFlow.update(with: state.inventory.e)
        self.cashFlow.update(with: state.inventory.x)
    }
}
