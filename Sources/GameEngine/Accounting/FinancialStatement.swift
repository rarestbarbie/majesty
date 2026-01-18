struct FinancialStatement {
    private(set) var costs: CostSummary
    private(set) var lines: Lines
}
extension FinancialStatement {
    init() {
        self.init(
            costs: .init(),
            lines: .zero,
        )
    }
}
extension FinancialStatement {
    private mutating func reset() {
        self.costs.reset()
        self.lines = .zero
    }
}
extension FinancialStatement {
    mutating func update(from building: Building) {
        self.reset()

        let valueConsumed: (l: Int64, e: Int64)
        valueConsumed.l = self.costs.update(with: building.inventory.l)
        valueConsumed.e = self.costs.update(with: building.inventory.e)
        self.lines = .compute(property: building, valueConsumed: valueConsumed)
    }

    mutating func update(from factory: Factory) {
        self.reset()

        let valueConsumed: (l: Int64, e: Int64)
        valueConsumed.l = self.costs.update(with: factory.inventory.l)
        valueConsumed.e = self.costs.update(with: factory.inventory.e)
        self.costs[.workers] = factory.spending.wages
        self.costs[.clerks] = factory.spending.salaries
        self.lines = .compute(factory: factory, valueConsumed: valueConsumed)
    }

    mutating func update(from pop: Pop) -> Int64 {
        self.reset()

        if  pop.type.stratum <= .Ward {
            let valueConsumed: (l: Int64, e: Int64)
            valueConsumed.l = self.costs.update(with: pop.inventory.l)
            valueConsumed.e = self.costs.update(with: pop.inventory.e)
            self.lines = .compute(property: pop, valueConsumed: valueConsumed)
            return 0
        } else {
            let consumption: Int64 = self.costs.update(with: pop.inventory.l)
                + self.costs.update(with: pop.inventory.e)
                + self.costs.update(with: pop.inventory.x)
            self.lines = .compute(free: pop)
            return consumption
        }
    }
}
extension FinancialStatement {
    var valueAdded: Int64 {
        self.lines.valueProduced - self.lines.valueConsumed
    }

    // var fixedCosts: Int64 {
    //     self.lines.operatingCosts + self.lines.carryingCosts
    // }

    var profit: Profit {
        .init(
            materialsCosts: self.lines.materialsCosts,
            operatingCosts: self.lines.operatingCosts,
            carryingCosts: self.lines.carryingCosts,
            revenue: self.lines.valueProduced
        )
    }
}
