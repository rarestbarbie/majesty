import Color
import D
import GameEconomy
import VectorCharts

struct CashAllocationStatement {
    private let factory: Bool
    private let buybacks: Int64
    private let dividend: Int64
    private let salaries: Int64
    private let wages: Int64
    private let l: Int64
    private let e: Int64
    private let x: Int64
}
extension CashAllocationStatement {
    var total: Int64 {
        self.buybacks +
        self.dividend +
        self.salaries +
        self.wages +
        self.l +
        self.e +
        self.x
    }
}
extension CashAllocationStatement {
    init(from budget: OperatingBudget) {
        self.init(
            factory: true,
            buybacks: budget.buybacks,
            dividend: budget.dividend,
            salaries: budget.clerks,
            wages: budget.workers,
            l: budget.l.total,
            e: budget.e.total,
            x: budget.x.total,
        )
    }
    init(from budget: PopBudget) {
        self.init(
            factory: false,
            buybacks: budget.buybacks,
            dividend: budget.dividend,
            salaries: 0,
            wages: 0,
            l: budget.l.total,
            e: budget.e.total,
            x: budget.x.total,
        )
    }
}
extension CashAllocationStatement {
    private subscript(item: CashAllocationItem) -> (label: String, share: Int64) {
        let label: String
        let share: Int64
        switch item {
        case .l:
            label = self.factory ? "Inputs" : "Life needs"
            share = self.l
        case .e:
            label = self.factory ? "Maintenance" : "Everyday needs"
            share = self.e
        case .x:
            label = self.factory ? "Capital expenditures" : "Luxury needs"
            share = self.x
        case .salaries:
            label = "Salaries"
            share = self.salaries
        case .wages:
            label = "Wages"
            share = self.wages
        case .dividend:
            label = "Dividends"
            share = self.dividend
        case .buybacks:
            label = "Buybacks"
            share = self.buybacks
        }
        return (label, share)
    }
    private func style(_ item: CashAllocationItem) -> String {
        "\(item.rawValue)"
    }

    func tooltip(item: CashAllocationItem) -> Tooltip {
        .instructions(style: .borderless) {
            let (label, share): (String, Int64) = self[item]
            $0[label] = (Double.init(share) / Double.init(self.total))[%3]
        }
    }

    func chart() -> PieChart<CashAllocationItem, PieChartLabel>? {
        if  self.total == 0 {
            return nil
        }

        let values: [
            (CashAllocationItem, (Int64, PieChartLabel))
        ] = CashAllocationItem.allCases.map {
            let (name, share): (String, Int64) = self[$0]
            return ($0, (share, .init(style: self.style($0), name: name)))
        }

        return .init(values: values)
    }
}
