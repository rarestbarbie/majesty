import GameEconomy
import GameState
import GameRules
import JavaScriptKit
import JavaScriptInterop
import VectorCharts

struct PopDetails {
    let id: PopID
    var needs: [ResourceNeed]
    var sales: [ResourceSale]

    var spending: PieChart<CashFlowItem, PieChartLabel>?

    init(id: PopID) {
        self.id = id
        self.needs = []
        self.sales = []
        self.spending = nil
    }
}
extension PopDetails {
    mutating func update(in context: GameContext) {
        guard
        let pop: PopContext = context.pops.table[self.id]
        else {
            return
        }

        self.needs.removeAll(keepingCapacity: true)
        self.needs.reserveCapacity(pop.state.nl.count + pop.state.ne.count + pop.state.nx.count)

        self.needs.update(inputs: pop.state.nl, tier: .l, rules: context.rules)
        self.needs.update(inputs: pop.state.ne, tier: .e, rules: context.rules)
        self.needs.update(inputs: pop.state.nx, tier: .x, rules: context.rules)

        self.sales.removeAll(keepingCapacity: true)
        self.sales.reserveCapacity(pop.state.out.count)

        for output: ResourceOutput in pop.state.out {
            self.sales.append(.init(
                label: context.rules[output.id],
                quantity: output.quantity,
                leftover: output.leftover,
                proceeds: output.proceeds
            ))
        }

        self.spending = pop.cashFlow.chart(rules: context.rules)
    }
}
extension PopDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case needs
        case sales
        case spending
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.needs] = self.needs
        js[.sales] = self.sales
        js[.spending] = self.spending
    }
}
