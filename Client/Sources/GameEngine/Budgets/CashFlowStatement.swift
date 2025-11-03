import D
import GameEconomy
import GameRules
import VectorCharts

struct CashFlowStatement {
    private var costs: [CashFlowItem: Int64]

    init() {
        self.costs = [:]
    }
}
extension CashFlowStatement {
    mutating func reset() {
        self.costs.removeAll(keepingCapacity: true)
    }
    mutating func update(with inputs: ResourceInputs) {
        self.update(with: inputs.tradeable.values.elements)
        self.update(with: inputs.inelastic.values.elements)
    }
    mutating func update<Price>(with inputs: [ResourceInput<Price>]) {
        for input: ResourceInput<Price> in inputs where input.valueConsumed > 0 {
            self.costs[.resource(input.id), default: 0] += input.valueConsumed
        }
    }

    subscript(item: CashFlowItem) -> Int64 {
        get { self.costs[item] ?? 0 }
        set { self.costs[item] = newValue == 0 ? nil : newValue }
    }
}
extension CashFlowStatement {
    func tooltip(rules: GameRules, item: CashFlowItem) -> Tooltip {
        let (share, total): (share: Int64, total: Int64) = self.costs.reduce(into: (0, 0)) {
            if $1.key == item {
                $0.share += $1.value
            }
            $0.total += $1.value
        }

        let label: String
        switch item {
        case .resource(let id): label = rules.resources[id]?.name ?? "???"
        case .workers: label = "Workers"
        case .clerks: label = "Clerks"
        }

        return .instructions(style: .borderless) {
            $0[label] = (Double.init(share) / Double.init(total))[%3]
        }
    }

    func chart(rules: GameRules) -> PieChart<CashFlowItem, PieChartLabel>? {
        if self.costs.isEmpty {
            return nil
        }

        var values: [(CashFlowItem, (Int64, PieChartLabel))] = self.costs.map {
            let label: PieChartLabel?

            switch $0 {
            case .resource(let id): label = rules.resources[id]?.label
            case .workers: label = .init(color: 0x71bac7, name: "Workers")
            case .clerks: label = .init(color: 0xdbd5d3, name: "Clerks")
            }

            return ($0, ($1, label ?? .init(color: 0xFFFFFF, name: "???")))
        }

        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }
}
