import Assert

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
    mutating func update(from pop: Pop) {
        // we assume if a pop produces a local resource, it doesn’t work as an employee
        if  let utilization: Double = pop.inventory.out.utilization {
            self.employmentBeforeEgress = utilization
            // min is necessary here, because Double may round slightly up for very large Int64s
            self.employedBeforeEgress = min(
                pop.z.size,
                Int64.init(Double.init(pop.z.size) * self.employmentBeforeEgress)
            )
        } else if pop.inventory.out.tradeable.isEmpty {
            // we know pop size must be positive, as it would have been pruned during pruning
            let employed: Int64 = pop.employed()
            self.employedBeforeEgress = employed
            self.employmentBeforeEgress = Double.init(employed) / Double.init(pop.z.size)
        } else if pop.type.stratum <= .Worker {
            self.employedBeforeEgress = pop.z.size
            self.employmentBeforeEgress = 1
        } else {
            self.employedBeforeEgress = 0
            self.employmentBeforeEgress = 0
        }

        #assert(0 ... 1 ~= self.employmentBeforeEgress, "Employment must be between 0 and 1")

        self.cashFlow.reset()
        self.cashFlow.update(with: pop.inventory.l)
        self.cashFlow.update(with: pop.inventory.e)
        self.cashFlow.update(with: pop.inventory.x)
    }
}
