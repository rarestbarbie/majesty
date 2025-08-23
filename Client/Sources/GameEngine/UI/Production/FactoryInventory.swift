import GameEconomy
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct FactoryInventory {
    var needs: [ResourceNeed]
    var sales: [ResourceSale]

    var spending: PieChart<CashFlowItem, PieChartLabel>?

    init() {
        self.needs = []
        self.sales = []
        self.spending = nil
    }
}
extension FactoryInventory {
    mutating func update(from factory: FactoryContext, in context: GameContext) {
        self.needs.removeAll(keepingCapacity: true)
        self.needs.reserveCapacity(factory.state.ni.count + factory.state.nv.count)
        self.needs.update(inputs: factory.state.ni, tier: .i, rules: context.rules)
        self.needs.update(inputs: factory.state.nv, tier: .v, rules: context.rules)

        self.sales.removeAll(keepingCapacity: true)
        self.sales.reserveCapacity(factory.state.out.count)

        for output: ResourceOutput in factory.state.out {
            self.sales.append(.init(
                label: context.rules[output.id],
                quantity: output.quantity,
                leftover: output.leftover,
                proceeds: output.proceeds,
            ))
        }

        self.spending = factory.cashFlow.chart(rules: context.rules)
    }
}
extension FactoryInventory: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case needs
        case sales
        case spending
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = FactoryDetailsTab.Inventory
        js[.needs] = self.needs
        js[.sales] = self.sales
        js[.spending] = self.spending
    }
}
