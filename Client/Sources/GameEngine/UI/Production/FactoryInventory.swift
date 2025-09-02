import GameRules
import GameEconomy
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct FactoryInventory {
    private var inventory: ResourceInventory
    private var spending: PieChart<CashFlowItem, PieChartLabel>?

    init() {
        self.inventory = .init()
        self.spending = nil
    }
}
extension FactoryInventory {
    mutating func update(from factory: FactoryContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = factory.policy?.currency else {
            return
        }

        self.inventory.reset(inputs: factory.state.ni.count + factory.state.nv.count)
        self.inventory.update(
            from: factory.state.ni,
            tier: .i,
            currency: currency,
            location: factory.state.on,
            snapshot: snapshot
        )
        self.inventory.update(
            from: factory.state.nv,
            tier: .v,
            currency: currency,
            location: factory.state.on,
            snapshot: snapshot
        )

        self.inventory.reset(outputs: factory.state.out.count)
        self.inventory.update(
            from: factory.state.out,
            currency: currency,
            location: factory.state.on,
            snapshot: snapshot
        )

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
        js[.needs] = self.inventory.needs
        js[.sales] = self.inventory.sales
        js[.spending] = self.spending
    }
}
