import Assert
import Fraction

struct ProfitMargins {
    let variableCosts: Int64
    let fixedCosts: Int64
    let revenue: Int64

    init(variableCosts: Int64, fixedCosts: Int64, revenue: Int64) {
        #assert(variableCosts >= 0, "Variable costs should never be negative!")
        #assert(fixedCosts >= 0, "Fixed costs should never be negative!")
        #assert(revenue >= 0, "Revenue should never be negative!")

        self.variableCosts = variableCosts
        self.fixedCosts = fixedCosts
        self.revenue = revenue
    }
}
extension ProfitMargins {
    var gross: Int64 { self.revenue - self.variableCosts }
    var grossMargin: Fraction? {
        guard self.revenue > 0 else {
            return nil
        }

        return self.gross %/ self.revenue
    }
    var operating: Int64 { self.gross - self.fixedCosts }
    var operatingMargin: Fraction? {
        guard self.revenue > 0 else {
            return nil
        }

        return self.operating %/ self.revenue
    }

    var operatingProfitability: Double {
        let totalCosts: Int64 = self.variableCosts + self.fixedCosts
        if  totalCosts > self.revenue {
            // implies `totalCosts > 0`
            return Double.init(self.revenue) / Double.init(totalCosts) - 1
        } else if self.revenue > totalCosts {
            // implies `self.revenue > 0`
            return 1 - Double.init(totalCosts) / Double.init(self.revenue)
        } else {
            return 0
        }
    }

    /// Ranges between 0 and 1, where 0 means break-even and 1 means losing more than total
    /// revenue.
    var operatingLossParameter: Double {
        guard
        let operatingMargin: Fraction else {
            return 1
        }
        if  operatingMargin.n > 0 {
            return 0
        }
        let operatingLoss: Int64 = -operatingMargin.n
        if  operatingLoss >= operatingMargin.d {
            return 1
        } else {
            return Double.init(operatingLoss %/ operatingMargin.d)
        }
    }
}
