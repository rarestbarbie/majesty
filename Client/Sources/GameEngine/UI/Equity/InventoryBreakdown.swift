import GameIDs
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct InventoryBreakdown<Tab> where Tab: InventoryTab {
    private var inventory: ResourceInventory
    private var costs: PieChart<CashFlowItem, PieChartLabel>?
    private var budget: PieChart<OperatingBudgetItem, PieChartLabel>?

    init() {
        self.inventory = .init()
        self.costs = nil
        self.budget = nil
    }
}
extension InventoryBreakdown {
    mutating func update(from pop: PopContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = pop.governedBy?.currency.id else {
            return
        }

        self.inventory.reset(
            inputs:
            pop.state.inventory.l.count +
            pop.state.inventory.e.count +
            pop.state.inventory.x.count,
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

        self.costs = pop.cashFlow.chart(rules: snapshot.rules)
        self.budget = nil
    }

    mutating func update(from factory: FactoryContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = factory.occupiedBy?.currency.id else {
            return
        }

        self.inventory.reset(
            inputs:
            factory.state.inventory.l.count +
            factory.state.inventory.e.count +
            factory.state.inventory.x.count
        )
        self.inventory.update(
            from: factory.state.inventory.l,
            tier: .i,
            currency: currency,
            location: factory.state.tile,
            snapshot: snapshot
        )
        self.inventory.update(
            from: factory.state.inventory.e,
            tier: .j,
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

        self.costs = factory.cashFlow.chart(rules: snapshot.rules)


        switch factory.budget {
        case .active(let budget)?:
            let statement: OperatingBudgetStatement = .init(from: budget)
            self.budget = statement.chart()

        default:
            self.budget = nil
        }
    }
}
extension InventoryBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case needs
        case sales
        case costs
        case budget
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Inventory
        js[.needs] = self.inventory.needs
        js[.sales] = self.inventory.sales
        js[.costs] = self.costs
        js[.budget] = self.budget
    }
}
