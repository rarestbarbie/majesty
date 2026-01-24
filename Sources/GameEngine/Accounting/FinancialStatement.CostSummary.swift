import ColorReference
import D
import GameEconomy
import GameRules
import GameUI
import VectorCharts

extension FinancialStatement {
    struct CostSummary {
        private(set) var items: [Cost]

        init() {
            self.items = []
        }
    }
}
extension FinancialStatement.CostSummary {
    mutating func reset() {
        self.items.removeAll(keepingCapacity: true)
    }

    mutating func update(with inputs: ResourceInputs) -> Int64 {
        var total: Int64 = 0
        for input: ResourceInput in inputs.all where input.valueConsumed > 0 {
            total += input.valueConsumed
            self.items.append(
                .resource(id: input.id, units: input.unitsConsumed, value: input.valueConsumed)
            )
        }
        return total
    }
    mutating func update(with cost: FinancialStatement.Cost) {
        if  cost.value > 0 {
            self.items.append(cost)
        }
    }
}
extension FinancialStatement.CostSummary {
    func tooltip(rules: GameMetadata, item: FinancialStatement.CostItem) -> Tooltip {
        let (share, total): (share: Int64, total: Int64) = self.items.reduce(into: (0, 0)) {
            if  $1.id == item {
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
        if self.items.isEmpty {
            return nil
        }

        var values: [(FinancialStatement.CostItem, (Int64, ColorReference))] = self.items.map {
            let label: ColorReference?

            switch $0 {
            case .resource(id: let id, _, _): label = .color(rules.resources[id].color)
            case .workers: label = .color(0x71bac7)
            case .clerks: label = .color(0xdbd5d3)
            }

            return ($0.id, ($0.value, label ?? .color(0xFFFFFF)))
        }

        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }
}
