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

    init(materialsCosts: Int64, operatingCosts: Int64, carryingCosts: Int64, revenue: Int64) {
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
