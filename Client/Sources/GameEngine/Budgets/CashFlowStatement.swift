import D
import GameEconomy
import GameRules
import VectorCharts

struct CashFlowStatement {
    private var items: [CashFlowItem: Int64]

    init() {
        self.items = [:]
    }
}
extension CashFlowStatement {
    mutating func reset() {
        self.items.removeAll(keepingCapacity: true)
    }
    mutating func update(with inputs: [ResourceInput]) {
        for input: ResourceInput in inputs where input.consumedValue > 0 {
            self.items[.resource(input.id), default: 0] += input.consumedValue
        }
    }

    subscript(item: CashFlowItem) -> Int64 {
        get { self.items[item] ?? 0 }
        set { self.items[item] = newValue == 0 ? nil : newValue }
    }
}
extension CashFlowStatement {
    func tooltip(rules: GameRules, item: CashFlowItem) -> Tooltip {
        let (share, total): (share: Int64, total: Int64) = self.items.reduce(into: (0, 0)) {
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
        if self.items.isEmpty {
            return nil
        }

        var values: [(CashFlowItem, (Int64, PieChartLabel))] = self.items.map {
            let label: PieChartLabel?

            switch $0 {
            case .resource(let id): label = rules.resources[id]?.label
            case .workers: label = .init(color: 0x7A8AFF, name: "Workers")
            case .clerks: label = .init(color: 0xAAAAAA, name: "Clerks")
            }

            return ($0, ($1, label ?? .init(color: 0xFFFFFF, name: "???")))
        }

        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }
}
