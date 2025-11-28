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
        let currency: CurrencyID = pop.region?.occupiedBy.currency.id else {
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
                name: snapshot.mines[mine.id]?.type.title,
                currency: currency,
                location: pop.state.tile,
                snapshot: snapshot
            )
        }

        self.costs = pop.stats.cashFlow.chart(rules: snapshot.rules)
        if  let budget: Pop.Budget = pop.state.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()
        } else {
            self.budget = nil
        }
    }

    mutating func update(from factory: FactoryContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: CurrencyID = factory.region?.occupiedBy.currency.id else {
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
            let worker: PopType = factory.type.workers.unit
            guard
            let workers: Workforce = factory.workers,
            let clerk: PopType = factory.type.clerks?.unit,
            let clerks: Workforce = factory.clerks else {
                return
            }

            $0[.pop(clerk), +, tooltip: .FactoryClerks] = clerks.count[/3] ^^ clerks.change
            $0[.pop(worker), +, tooltip: .FactoryWorkers] = workers.count[/3] ^^ workers.change
        }

        self.costs = factory.cashFlow.chart(rules: snapshot.rules)


        switch factory.state.budget {
        case .active(let budget)?:
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()

        default:
            self.budget = nil
        }
    }

    mutating func update(from building: BuildingContext, in snapshot: borrowing GameSnapshot) {
        guard
        let currency: CurrencyID = building.region?.occupiedBy.currency.id else {
            return
        }

        self.tiers = [
            .init(id: .l, label: "Operations", value: building.state.z.fl),
            .init(id: .e, label: "Maintenance", value: building.state.z.fe),
            .init(id: .x, label: "Development", value: building.state.z.fx),
        ]

        let inputs: ResourceInputs

        switch self.focus {
        case .l: inputs = building.state.inventory.l
        case .e: inputs = building.state.inventory.e
        case .x: inputs = building.state.inventory.x
        }

        self.reset(inputs: inputs.count)
        self.update(
            from: inputs,
            tier: self.focus,
            currency: currency,
            location: building.state.tile,
            snapshot: snapshot
        )

        self.reset(outputs: building.state.inventory.out.count)
        self.update(
            from: building.state.inventory.out,
            currency: currency,
            location: building.state.tile,
            snapshot: snapshot
        )

        self.terms = Term.list {
            $0[.buildingsActive, +, tooltip: .BuildingActive] = building.state.Δ.active[/3]
            $0[.buildingsVacant, -, tooltip: .BuildingVacant] = building.state.Δ.vacant[/3]
        }

        self.costs = building.stats.cashFlow.chart(rules: snapshot.rules)
        self.budget = building.state.budget.map {
            let statement: CashAllocationStatement = .init(from: $0)
            return statement.chart()
        } ?? nil
    }
}
extension InventoryBreakdown {
    private mutating func update(
        from inputs: ResourceInputs,
        tier: ResourceTierIdentifier,
        currency: CurrencyID,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, input): (Resource, ResourceInput) in inputs.tradeable {
            let market: BlocMarket.State? = snapshot.markets.tradeable[id / currency]?.state
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules.resources[id].label,
                    tier: tier,
                    stockpile: input.units.total,
                    filled: input.unitsConsumed,
                    demand: input.unitsDemanded,
                    price: market?.history.last?.prices,
                )
            )
        }
        for (id, input): (Resource, ResourceInput) in inputs.segmented {
            let market: LocalMarket? = snapshot.markets.segmented[id / location]
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules.resources[id].label,
                    tier: tier,
                    stockpile: input.units.total,
                    filled: input.units.added,
                    demand: input.unitsDemanded,
                    price: market?.price,
                )
            )
        }
    }

    private mutating func update(
        from outputs: ResourceOutputs,
        mine: MineID? = nil,
        name: String? = nil,
        currency: CurrencyID,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, output): (Resource, ResourceOutput) in outputs.tradeable {
            let market: BlocMarket.State? = snapshot.markets.tradeable[id / currency]?.state
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules.resources[output.id].label,
                    mine: mine,
                    name: name,
                    unitsSold: output.unitsSold,
                    price: market?.history.last?.prices
                )
            )
        }
        for (id, output): (Resource, ResourceOutput) in outputs.segmented {
            let market: LocalMarket? = snapshot.markets.segmented[id / location]
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules.resources[output.id].label,
                    mine: mine,
                    name: name,
                    unitsSold: output.unitsSold,
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
