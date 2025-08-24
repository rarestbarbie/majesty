import GameRules
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
    mutating func update(from factory: FactoryContext, in snapshot: borrowing GameSnapshot) {
        self.needs.removeAll(keepingCapacity: true)
        self.needs.reserveCapacity(factory.state.ni.count + factory.state.nv.count)
        self.needs.update(
            inputs: factory.state.ni,
            currency: factory.policy?.currency,
            tier: .i,
            from: snapshot
        )
        self.needs.update(
            inputs: factory.state.nv,
            currency: factory.policy?.currency,
            tier: .v,
            from: snapshot
        )

        self.sales.removeAll(keepingCapacity: true)
        self.sales.reserveCapacity(factory.state.out.count)

        for output: ResourceOutput in factory.state.out {
            self.sales.append(.init(
                label: snapshot.rules[output.id],
                quantity: output.quantity,
                leftover: output.leftover,
                proceeds: output.proceeds,
            ))
        }

        self.spending = factory.cashFlow.chart(rules: snapshot.rules)
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
