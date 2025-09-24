import GameRules
import GameEconomy
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
        let currency: Fiat = pop.policy?.currency else {
            return
        }

        self.inventory.reset(
            inputs: pop.state.nl.count + pop.state.ne.count + pop.state.nx.count,
        )

        self.inventory.update(
            from: pop.state.nl,
            tier: .l,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )
        self.inventory.update(
            from: pop.state.ne,
            tier: .e,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )
        self.inventory.update(
            from: pop.state.nx,
            tier: .x,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )

        self.inventory.reset(outputs: pop.state.out.count)
        self.inventory.update(
            from: pop.state.out,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )

        self.spending = pop.cashFlow.chart(rules: snapshot.rules)
    }

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
