import GameEconomy
import GameIDs
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct InventoryBreakdown<Tab> where Tab: InventoryTab {
    var focus: ResourceTierIdentifier

    private var tiers: [ResourceNeedMeter]
    private var needs: [ResourceNeed]
    private var sales: [ResourceSale]
    private var costs: PieChart<CashFlowItem, PieChartLabel>?
    private var budget: PieChart<CashAllocationItem, PieChartLabel>?

    init(focus: ResourceTierIdentifier) {
        self.focus = focus
        self.tiers = []
        self.needs = []
        self.sales = []
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
        let currency: Fiat = pop.governedBy?.currency.id else {
            return
        }

        self.tiers = [
            .init(id: .l, label: "Subsistence", value: pop.state.today.fl),
            .init(id: .e, label: "Everyday", value: pop.state.today.fe),
            .init(id: .x, label: "Luxury", value: pop.state.today.fx),
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
        let currency: Fiat = factory.occupiedBy?.currency.id else {
            return
        }

        self.tiers = [
            .init(id: .l, label: "Materials", value: factory.state.today.fl),
            .init(id: .e, label: "Corporate", value: factory.state.today.fe),
            .init(id: .x, label: "Expansion", value: factory.state.today.fx),
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
        for (id, input): (Resource, TradeableInput) in inputs.tradeable {
            let market: Market? = snapshot.markets.tradeable[id / currency]
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules[id],
                    tier: tier,
                    unitsAcquired: input.unitsAcquired,
                    unitsConsumed: input.unitsConsumed,
                    unitsDemanded: input.unitsDemanded,
                    priceAtMarket: market?.history.last?.prices,
                    price: nil
                )
            )
        }
        for (id, input): (Resource, InelasticInput) in inputs.inelastic {
            let market: LocalMarket? = snapshot.markets.inelastic[location, id]
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules[id],
                    tier: tier,
                    unitsAcquired: input.unitsAcquired,
                    unitsConsumed: input.unitsPurchased,
                    unitsDemanded: input.unitsDemanded,
                    priceAtMarket: nil,
                    price: market?.price,
                )
            )
        }
    }

    private mutating func update(
        from outputs: ResourceOutputs,
        currency: Fiat,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, output): (Resource, TradeableOutput) in outputs.tradeable {
            let market: Market? = snapshot.markets.tradeable[id / currency]
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules[output.id],
                    unitsProduced: output.unitsProduced,
                    unitsSold: output.unitsSold,
                    valueSold: output.valueSold,
                    priceAtMarket: market?.history.last?.prices,
                    price: nil
                )
            )
        }
        for (id, output): (Resource, InelasticOutput) in outputs.inelastic {
            let market: LocalMarket? = snapshot.markets.inelastic[location, id]
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules[output.id],
                    unitsProduced: output.unitsProduced,
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
        case tiers
        case needs
        case sales
        case costs
        case budget
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Inventory
        js[.tiers] = self.tiers
        js[.needs] = self.needs
        js[.sales] = self.sales
        js[.costs] = self.costs
        js[.budget] = self.budget
    }
}
