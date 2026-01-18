import Assert
import GameEconomy

extension FinancialStatement {
    struct Lines {
        /// Costs of goods sold, including hourly labor.
        let materialsCosts: Int64
        /// The portion of fixed costs associated with operating the business.
        let operatingCosts: Int64
        /// The portion of fixed costs associated with carrying idle capacity.
        let carryingCosts: Int64
        /// GDP calculation: approximate value of goods produced this turn. Synonymous with revenue.
        let valueProduced: Int64
        /// GDP calculation: approximate value of non-labor, non-capital inputs consumed this turn.
        let valueConsumed: Int64

        private init(
            materialsCosts: Int64,
            operatingCosts: Int64,
            carryingCosts: Int64,
            valueProduced: Int64,
            valueConsumed: Int64
        ) {
            #assert(materialsCosts >= 0, "Materials costs should never be negative!")
            #assert(operatingCosts >= 0, "Operating costs should never be negative!")
            #assert(carryingCosts >= 0, "Carrying costs should never be negative!")
            #assert(valueProduced >= 0, "Revenue should never be negative!")

            self.materialsCosts = materialsCosts
            self.operatingCosts = operatingCosts
            self.carryingCosts = carryingCosts
            self.valueProduced = valueProduced
            self.valueConsumed = valueConsumed
        }
    }
}
extension FinancialStatement.Lines {
    static var zero: Self {
        .init(
            materialsCosts: 0,
            operatingCosts: 0,
            carryingCosts: 0,
            valueProduced: 0,
            valueConsumed: 0
        )
    }

    static func compute(
        property: some LegalEntityState<some BackgroundableMetrics>,
        valueConsumed: (
            l: Int64, // materials costs
            e: Int64 // fixed costs
        )
    ) -> Self {
        /// this is the minimum fraction of `fe` we would require if we only paid maintenance
        /// for active facilities
        let expected: Double = Double.init(property.z.active) / Double.init(property.z.total)
        let prorate: Double = max(0, property.z.fe - expected)
        /// this is a reasonable underestimate of the amount of maintenance costs that went
        /// towards maintaining vacant facilities
        let carryingCosts: Int64 = Int64.init(Double.init(valueConsumed.e) * prorate)
        return .init(
            materialsCosts: valueConsumed.l,
            operatingCosts: valueConsumed.e - carryingCosts,
            carryingCosts: carryingCosts,
            valueProduced: property.inventory.out.valueProduced,
            valueConsumed: valueConsumed.l + valueConsumed.e
        )
    }

    static func compute(factory: Factory, valueConsumed: (l: Int64, e: Int64)) -> Self {
        // for Factories, compliance costs scale with number of workers, so all compliance costs
        // are treated as operating costs=
        return .init(
            materialsCosts: valueConsumed.l + factory.spending.wages,
            operatingCosts: valueConsumed.e + factory.spending.salariesUsed,
            carryingCosts: factory.spending.salariesIdle,
            valueProduced: factory.inventory.out.valueProduced,
            valueConsumed: valueConsumed.l + valueConsumed.e
        )
    }

    static func compute(free pop: Pop) -> Self {
        var valueProduced: Int64 = pop.inventory.out.valueProduced
        for mining: MiningJob in pop.mines.values {
            for output: ResourceOutput in mining.out.all {
                valueProduced += output.valueProduced
            }
        }
        return .init(
            materialsCosts: 0,
            operatingCosts: 0,
            carryingCosts: 0,
            valueProduced: valueProduced,
            valueConsumed: 0
        )
    }
}
