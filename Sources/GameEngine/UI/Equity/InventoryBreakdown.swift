import D
import GameEconomy
import GameIDs
import GameUI
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct InventoryBreakdown<Tab> where Tab: InventoryTab {
    var focus: ResourceTierIdentifier

    private var tiers: [ResourceNeedMeter]
    private var needs: [ResourceNeed]
    private var sales: [ResourceSale]
    private var terms: [Term]
    private var costs: PieChart<CashFlowItem, PieChartLabel>?
    private var budget: PieChart<CashAllocationItem, PieChartLabel>?

    init(focus: ResourceTierIdentifier) {
        self.focus = focus
        self.tiers = []
        self.needs = []
        self.sales = []
        self.terms = []
        self.costs = nil
        self.budget = nil
    }
}
extension InventoryBreakdown {
    mutating func reset(inputs: Int) {
        self.needs.removeAll(keepingCapacity: true)
        self.needs.reserveCapacity(inputs)
    }
    mutating func reset(outputs: Int) {
        self.sales.removeAll(keepingCapacity: true)
        self.sales.reserveCapacity(outputs)
    }

    mutating func update(from pop: PopContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = pop.region?.occupiedBy.currency.id else {
            return
        }

        self.tiers = [
            .init(id: .l, label: "Subsistence", value: pop.state.z.fl),
            .init(id: .e, label: "Everyday", value: pop.state.z.fe),
            .init(id: .x, label: "Luxury", value: pop.state.z.fx),
        ]

        let inputs: ResourceInputs

        switch self.focus {
        case .l: inputs = pop.state.inventory.l
        case .e: inputs = pop.state.inventory.e
        case .x: inputs = pop.state.inventory.x
        }

        self.reset(inputs: inputs.count)
        self.update(
            from: inputs,
            tier: self.focus,
            currency: currency,
            location: pop.state.tile,
            snapshot: snapshot
        )

        self.reset(outputs: pop.state.inventory.out.count)
        self.update(
            from: pop.state.inventory.out,
            currency: currency,
            location: pop.state.tile,
            snapshot: snapshot
        )

        for mine: MiningJob in pop.state.mines.values {
            self.update(
                from: mine.out,
                mine: mine.id,
                name: snapshot.mines[mine.id]?.type.name,
                currency: currency,
                location: pop.state.tile,
                snapshot: snapshot
            )
        }

        self.costs = pop.cashFlow.chart(rules: snapshot.rules)
        if  let budget: PopBudget = pop.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()
        } else {
            self.budget = nil
        }
    }

    mutating func update(from factory: FactoryContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: Fiat = factory.region?.occupiedBy.currency.id else {
            return
        }

        self.tiers = [
            .init(id: .l, label: "Materials", value: factory.state.z.fl),
            .init(id: .e, label: "Corporate", value: factory.state.z.fe),
            .init(id: .x, label: "Expansion", value: factory.state.z.fx),
        ]

        let inputs: ResourceInputs

        switch self.focus {
        case .l: inputs = factory.state.inventory.l
        case .e: inputs = factory.state.inventory.e
        case .x: inputs = factory.state.inventory.x
        }

        self.reset(inputs: inputs.count)
        self.update(
            from: inputs,
            tier: self.focus,
            currency: currency,
            location: factory.state.tile,
            snapshot: snapshot
        )

        self.reset(outputs: factory.state.inventory.out.count)
        self.update(
            from: factory.state.inventory.out,
            currency: currency,
            location: factory.state.tile,
            snapshot: snapshot
        )

        self.terms = Term.list {
            let workersType: PopType = factory.type.workers.unit
            guard
            let workers: Workforce = factory.workers,
            let clerksType: PopType = factory.type.clerks?.unit,
            let clerks: Workforce = factory.clerks else {
                return
            }

            $0[.pop(clerksType), (+)] = clerks.count[/3] ^^ clerks.change
            $0[.pop(workersType), (+)] = workers.count[/3] ^^ workers.change
        }

        self.costs = factory.cashFlow.chart(rules: snapshot.rules)


        switch factory.budget {
        case .active(let budget)?:
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()

        default:
            self.budget = nil
        }
    }
}
extension InventoryBreakdown {
    private mutating func update(
        from inputs: ResourceInputs,
        tier: ResourceTierIdentifier,
        currency: Fiat,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, input): (Resource, ResourceInput<Double>) in inputs.tradeable {
            let market: BlocMarket.State? = snapshot.markets.tradeable[id / currency]?.state
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules[id],
                    tier: tier,
                    stockpile: input.units.total,
                    filled: input.unitsConsumed,
                    demand: input.unitsDemanded,
                    priceAtMarket: market?.history.last?.prices,
                    price: nil
                )
            )
        }
        for (id, input): (Resource, ResourceInput<Never>) in inputs.inelastic {
            let market: LocalMarket? = snapshot.markets.inelastic[id / location]
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules[id],
                    tier: tier,
                    stockpile: input.units.total,
                    filled: input.units.added,
                    demand: input.unitsDemanded,
                    priceAtMarket: nil,
                    price: market?.price,
                )
            )
        }
    }

    private mutating func update(
        from outputs: ResourceOutputs,
        mine: MineID? = nil,
        name: String? = nil,
        currency: Fiat,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, output): (Resource, ResourceOutput<Double>) in outputs.tradeable {
            let market: BlocMarket.State? = snapshot.markets.tradeable[id / currency]?.state
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules[output.id],
                    mine: mine,
                    name: name,
                    unitsProduced: output.units.added,
                    unitsSold: output.unitsSold,
                    valueSold: output.valueSold,
                    priceAtMarket: market?.history.last?.prices,
                    price: nil
                )
            )
        }
        for (id, output): (Resource, ResourceOutput<Never>) in outputs.inelastic {
            let market: LocalMarket? = snapshot.markets.inelastic[id / location]
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules[output.id],
                    mine: mine,
                    name: name,
                    unitsProduced: output.units.added,
                    unitsSold: output.unitsSold,
                    valueSold: output.valueSold,
                    priceAtMarket: nil,
                    price: market?.price,
                )
            )
        }
    }
}
extension InventoryBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case focus
        case tiers
        case needs
        case sales
        case terms
        case costs
        case budget
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Inventory
        js[.focus] = self.focus
        js[.tiers] = self.tiers
        js[.needs] = self.needs
        js[.sales] = self.sales
        js[.terms] = self.terms
        js[.costs] = self.costs
        js[.budget] = self.budget
    }
}
