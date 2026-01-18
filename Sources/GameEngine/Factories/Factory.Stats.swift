import Assert

extension Factory {
    struct Stats {
        private(set) var utilization: Double
        private(set) var productivity: Int64
        private(set) var financial: FinancialStatement
    }
}
extension Factory.Stats {
    init() {
        self.init(
            utilization: 0,
            productivity: 0,
            financial: .init()
        )
    }
}
extension Factory.Stats {
    mutating func startIndexCount(_ factory: Factory) {
        if  let utilization: Double = factory.inventory.out.utilization {
            #assert(0 ... 1 ~= utilization, "Utilization must be between 0 and 1")
            self.utilization = utilization
        } else {
            self.utilization = 1
        }

        self.financial.update(from: factory)
    }

    mutating func afterIndexCount(_ factory: Factory, in region: RegionalProperties) {
        self.productivity = region.modifiers.factoryProductivity[factory.type]?.value ?? 1
    }
}
