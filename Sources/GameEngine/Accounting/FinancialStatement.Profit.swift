import Assert
import Fraction

extension FinancialStatement {
    struct Profit {
        /// Costs of goods sold, including hourly labor.
        let materialsCosts: Int64
        /// The portion of fixed costs associated with operating the business.
        let operatingCosts: Int64
        /// The portion of fixed costs associated with carrying idle capacity.
        let carryingCosts: Int64
        let revenue: Int64
    }
}
extension FinancialStatement.Profit {
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
    ///
    /// This metric is always in the range of –1 to +1.
    var π: Double {
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
