import Assert
import GameIDs

extension Pop {
    struct Stats {
        private(set) var employmentBeforeEgress: Double
        private(set) var employedBeforeEgress: Int64
        private(set) var financial: FinancialStatement
        private(set) var consumption: Int64
    }
}
extension Pop.Stats {
    init() {
        self.init(
            employmentBeforeEgress: 0,
            employedBeforeEgress: 0,
            financial: .init(),
            consumption: 0
        )
    }
}
extension Pop.Stats {
    mutating func startIndexCount(_ pop: Pop) {
        // we assume if a pop produces a local resource, it doesn’t work as an employee
        if  let utilization: Double = pop.inventory.out.utilization {
            self.employmentBeforeEgress = utilization
            // min is necessary here, because Double may round slightly up for very large Int64s
            self.employedBeforeEgress = min(
                pop.z.active,
                Int64.init(Double.init(pop.z.active) * self.employmentBeforeEgress)
            )
        } else if pop.inventory.out.tradeable.isEmpty {
            // we know pop size must be positive, as it would have been pruned during pruning
            let employed: Int64 = pop.employed()
            self.employedBeforeEgress = employed
            self.employmentBeforeEgress = pop.z.active > 0
                ? Double.init(employed) / Double.init(pop.z.active)
                : 0
        } else if pop.type.stratum <= .Worker {
            self.employedBeforeEgress = pop.z.active
            self.employmentBeforeEgress = 1
        } else {
            self.employedBeforeEgress = 0
            self.employmentBeforeEgress = 0
        }

        #assert(0 ... 1 ~= self.employmentBeforeEgress, "Employment must be between 0 and 1")

        self.consumption = self.financial.update(from: pop)
    }
}
