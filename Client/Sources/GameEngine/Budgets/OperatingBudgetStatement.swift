import Color
import D
import GameEconomy
import VectorCharts

struct OperatingBudgetStatement {
    let buybacks: Int64
    let dividend: Int64
    let labor: Int64
    let l: Int64
    let e: Int64
    let x: Int64
}
extension OperatingBudgetStatement {
    init(from budget: OperatingBudget) {
        self.buybacks = budget.buybacks
        self.dividend = budget.dividend
        self.labor = budget.workers + budget.clerks
        self.l = budget.l.total
        self.e = budget.e.total
        self.x = budget.x.total
    }
}
extension OperatingBudgetStatement {
    subscript(item: OperatingBudgetItem) -> (label: String, share: Int64) {
        let label: String
        let share: Int64
        switch item {
        case .maintenance:
            label = "Maintenance"
            share = l
        case .inputs:
            label = "Inputs"
            share = e
        case .labor:
            label = "Labor"
            share = labor
        case .capex:
            label = "CapEx"
            share = x
        case .dividend:
            label = "Dividends"
            share = self.dividend
        case .buybacks:
            label = "Buybacks"
            share = self.buybacks
        }
        return (label, share)
    }

    var total: Int64 {
        self.labor + self.l + self.e + self.x + self.dividend + self.buybacks
    }

    func tooltip(item: OperatingBudgetItem) -> Tooltip {
        .instructions(style: .borderless) {
            let (label, share): (String, Int64) = self[item]
            $0[label] = (Double.init(share) / Double.init(self.total))[%3]
        }
    }

    func chart() -> PieChart<OperatingBudgetItem, PieChartLabel>? {
        if  self.total == 0 {
            return nil
        }

        let values: [(OperatingBudgetItem, (Int64, PieChartLabel))] = OperatingBudgetItem.allCases.map {
            let (name, share): (String, Int64) = self[$0]
            let color: Color
            switch $0 {
            case .buybacks: color = 0x50FFD0
            case .dividend: color = 0x59A8F0
            case .labor: color = 0xE15759
            case .inputs: color = 0xCABAAA
            case .maintenance: color = 0x9A9FAA
            case .capex: color = 0xF2CE6B
            }
            return ($0, (share, .init(color: color, name: name)))
        }

        return .init(values: values)
    }
}
