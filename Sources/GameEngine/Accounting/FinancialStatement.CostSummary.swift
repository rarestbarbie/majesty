import ColorReference
import D
import GameEconomy
import GameRules
import GameUI
import VectorCharts

extension FinancialStatement {
    struct CostSummary {
        private var costs: [CostItem: Int64]

        init() {
            self.costs = [:]
        }
    }
}
extension FinancialStatement.CostSummary {
    mutating func reset() {
        self.costs.removeAll(keepingCapacity: true)
    }
    mutating func update(with inputs: ResourceInputs) -> Int64 {
        var total: Int64 = 0
        for input: ResourceInput in inputs.all where input.valueConsumed > 0 {
            total += input.valueConsumed
            self.costs[.resource(input.id), default: 0] += input.valueConsumed
        }
        return total
    }

    subscript(item: FinancialStatement.CostItem) -> Int64 {
        get { self.costs[item] ?? 0 }
        set { self.costs[item] = newValue == 0 ? nil : newValue }
    }
}
extension FinancialStatement.CostSummary {
    func tooltip(rules: GameMetadata, item: FinancialStatement.CostItem) -> Tooltip {
        let (share, total): (share: Int64, total: Int64) = self.costs.reduce(into: (0, 0)) {
            if $1.key == item {
                $0.share += $1.value
            }
            $0.total += $1.value
        }

        let label: String
        switch item {
        case .resource(let id): label = rules.resources[id].title
        case .workers: label = "Workers"
        case .clerks: label = "Clerks"
        }

        return .instructions(style: .borderless) {
            $0[label] = (Double.init(share) / Double.init(total))[%3]
        }
    }

    func chart(rules: GameMetadata) -> PieChart<FinancialStatement.CostItem, ColorReference>? {
        if self.costs.isEmpty {
            return nil
        }

        var values: [(FinancialStatement.CostItem, (Int64, ColorReference))] = self.costs.map {
            let label: ColorReference?

            switch $0 {
            case .resource(let id): label = .color(rules.resources[id].color)
            case .workers: label = .color(0x71bac7)
            case .clerks: label = .color(0xdbd5d3)
            }

            return ($0, ($1, label ?? .color(0xFFFFFF)))
        }

        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }
}
