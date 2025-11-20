import Fraction

struct ProfitMargins {
    let variableCosts: Int64
    let fixedCosts: Int64
    let revenue: Int64
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

    /// Ranges between 0 and 1, where 0 means break-even and 1 means losing more than total
    /// revenue.
    var operatingLossParameter: Double {
        guard
        let operatingMargin: Fraction,
            operatingMargin.n < 0 else {
            return 1
        }
        let operatingLoss: Int64 = -operatingMargin.n
        if  operatingLoss >= operatingMargin.d {
            return 1
        } else {
            return Double.init(operatingLoss %/ operatingMargin.d)
        }
    }
}
