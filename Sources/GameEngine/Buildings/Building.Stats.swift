import Assert

extension Building {
    struct Stats {
        private(set) var utilization: Double
        private(set) var financial: FinancialStatement
    }
}
extension Building.Stats {
    init() {
        self.init(utilization: 0, financial: .init())
    }
}
extension Building.Stats {
    mutating func startIndexCount(_ building: Building) {
        if  let utilization: Double = building.inventory.out.utilization {
            #assert(0 ... 1 ~= utilization, "Utilization must be between 0 and 1")
            self.utilization = utilization
        } else {
            self.utilization = 1
        }

        self.financial.update(from: building)
    }
}
