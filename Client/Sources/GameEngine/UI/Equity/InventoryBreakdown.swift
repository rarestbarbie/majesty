import GameIDs
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct InventoryBreakdown<Tab> where Tab: InventoryTab {
    private var inventory: ResourceInventory
    private var spending: PieChart<CashFlowItem, PieChartLabel>?

    init() {
        self.inventory = .init()
        self.spending = nil
    }
}
extension InventoryBreakdown {
    mutating func update(from pop: PopContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = pop.governedBy?.currency.id else {
            return
        }

        self.inventory.reset(
            inputs: pop.state.inventory.l.count + pop.state.inventory.e.count + pop.state.inventory.x.count,
        )

        self.inventory.update(
            from: pop.state.inventory.l,
            tier: .l,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )
        self.inventory.update(
            from: pop.state.inventory.e,
            tier: .e,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )
        self.inventory.update(
            from: pop.state.inventory.x,
            tier: .x,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )

        self.inventory.reset(outputs: pop.state.inventory.out.count)
        self.inventory.update(
            from: pop.state.inventory.out,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )

        self.spending = pop.cashFlow.chart(rules: snapshot.rules)
    }

    mutating func update(from factory: FactoryContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = factory.occupiedBy?.currency.id else {
            return
        }

        self.inventory.reset(inputs: factory.state.inventory.e.count + factory.state.inventory.x.count)
        self.inventory.update(
            from: factory.state.inventory.e,
            tier: .i,
            currency: currency,
            location: factory.state.tile,
            snapshot: snapshot
        )
        self.inventory.update(
            from: factory.state.inventory.x,
            tier: .v,
            currency: currency,
            location: factory.state.tile,
            snapshot: snapshot
        )

        self.inventory.reset(outputs: factory.state.inventory.out.count)
        self.inventory.update(
            from: factory.state.inventory.out,
            currency: currency,
            location: factory.state.tile,
            snapshot: snapshot
        )

        self.spending = factory.cashFlow.chart(rules: snapshot.rules)
    }
}
extension InventoryBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case needs
        case sales
        case spending
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Inventory
        js[.needs] = self.inventory.needs
        js[.sales] = self.inventory.sales
        js[.spending] = self.spending
    }
}
