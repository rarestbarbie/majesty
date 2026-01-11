import Assert
import Fraction

struct ProfitMargins {
    /// Costs of goods sold, including hourly labor.
    let materialsCosts: Int64
    /// The portion of fixed costs associated with operating the business.
    let operatingCosts: Int64
    /// The portion of fixed costs associated with carrying idle capacity.
    let carryingCosts: Int64
    let revenue: Int64

    private init(materialsCosts: Int64, operatingCosts: Int64, carryingCosts: Int64, revenue: Int64) {
        #assert(materialsCosts >= 0, "Materials costs should never be negative!")
        #assert(operatingCosts >= 0, "Operating costs should never be negative!")
        #assert(carryingCosts >= 0, "Carrying costs should never be negative!")
        #assert(revenue >= 0, "Revenue should never be negative!")

        self.materialsCosts = materialsCosts
        self.operatingCosts = operatingCosts
        self.carryingCosts = carryingCosts
        self.revenue = revenue
    }
}
extension ProfitMargins {
    static var undefined: Self {
        .init(materialsCosts: 0, operatingCosts: 0, carryingCosts: 0, revenue: 0)
    }

    static func compute(factory: Factory) -> Self {
        // for Factories, compliance costs scale with number of workers, so all compliance costs
        // are treated as operating costs
        .init(
            materialsCosts: factory.inventory.l.valueConsumed + factory.spending.wages,
            operatingCosts: factory.inventory.e.valueConsumed + factory.spending.salariesUsed,
            carryingCosts: factory.spending.salariesIdle,
            revenue: factory.inventory.out.valueProduced
        )
    }

    static func compute(asset: some LegalEntityState<some BackgroundableMetrics>) -> Self {
        /// this is the minimum fraction of `fe` we would require if we only paid maintenance
        /// for active facilities
        let expected: Double = Double.init(asset.z.active) / Double.init(asset.z.total)
        let prorate: Double = max(0, asset.z.fe - expected)

        let fixedCosts: Int64 = asset.inventory.e.valueConsumed
        /// this is a reasonable underestimate of the amount of maintenance costs that went
        /// towards maintaining vacant facilities
        let carryingCosts: Int64 = Int64.init(Double.init(fixedCosts) * prorate)
        return .init(
            materialsCosts: asset.inventory.l.valueConsumed,
            operatingCosts: fixedCosts - carryingCosts,
            carryingCosts: carryingCosts,
            revenue: asset.inventory.out.valueProduced
        )
    }
}
extension ProfitMargins {
    var fixedCosts: Int64 {
        self.operatingCosts + self.carryingCosts
    }
}
extension ProfitMargins {
    var gross: Int64 { self.revenue - self.materialsCosts }
    var grossMargin: Fraction? {
        guard self.revenue > 0 else {
            return nil
        }

        return self.gross %/ self.revenue
    }

    var contribution: Int64 { self.gross - self.operatingCosts }
    var contributionMargin: Fraction? {
        guard self.revenue > 0 else {
            return nil
        }

        return self.contribution %/ self.revenue
    }

    var operating: Int64 { self.contribution - self.carryingCosts }
    var operatingMargin: Fraction? {
        guard self.revenue > 0 else {
            return nil
        }

        return self.operating %/ self.revenue
    }

    /// The marginal profitability is associated with **contribution margin**, i.e. how much
    /// profit is generated after deducting only the share of fixed costs associated with
    /// actively utilized capacity.
    var marginalProfitability: Double {
        let variableCosts: Int64 = self.materialsCosts + self.operatingCosts
        if  variableCosts > self.revenue {
            // implies `variableCosts > 0`
            return Double.init(self.revenue) / Double.init(variableCosts) - 1
        } else if self.revenue > variableCosts {
            // implies `self.revenue > 0`
            return 1 - Double.init(variableCosts) / Double.init(self.revenue)
        } else {
            return 0
        }
    }
}
