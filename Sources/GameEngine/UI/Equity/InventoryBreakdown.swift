import D
import GameEconomy
import GameIDs
import GameState
import GameUI
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct InventoryBreakdown<Tab>: Sendable where Tab: InventoryTab {
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

    mutating func update(from pop: PopSnapshot, in cache: borrowing GameUI.Cache) {
        let currency: CurrencyID = pop.region.currency.id
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
            cache: cache,
            progressive: false
        )

        self.reset(outputs: pop.state.inventory.out.count)
        self.update(
            from: pop.state.inventory.out,
            currency: currency,
            location: pop.state.tile,
            cache: cache
        )

        for mine: MiningJob in pop.state.mines.values {
            self.update(
                from: mine.out,
                mine: mine.id,
                name: cache.mines[mine.id]?.type.title,
                currency: currency,
                location: pop.state.tile,
                cache: cache
            )
        }

        self.terms = Term.list {
            guard case .Ward = pop.state.type.stratum else {
                return
            }

            let Δ: TurnDelta<Pop.Dimensions> = pop.state.Δ
            // reusing the buildings indicators for slaves
            $0[.buildingsActive, +, tooltip: .PopActive, help: .PopActiveHelp] = Δ.active[/3]
            $0[.buildingsVacant, -, tooltip: .PopVacant, help: .PopVacantHelp] = Δ.vacant[/3]
        }

        self.costs = pop.stats.cashFlow.chart(rules: cache.rules)
        if  let budget: Pop.Budget = pop.state.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()
        } else {
            self.budget = nil
        }
    }

    mutating func update(from factory: FactorySnapshot, in cache: borrowing GameUI.Cache) {
        let currency: CurrencyID = factory.region.currency.id

        self.tiers = [
            .init(id: .l, label: "Materials", value: factory.state.z.fl),
            .init(id: .e, label: "Corporate", value: factory.state.z.fe),
            .init(id: .x, label: "Expansion", value: factory.state.z.fx),
        ]

        let progressive: Bool
        let inputs: ResourceInputs

        switch self.focus {
        case .l: (inputs, progressive) = (factory.state.inventory.l, false)
        case .e: (inputs, progressive) = (factory.state.inventory.e, false)
        case .x: (inputs, progressive) = (factory.state.inventory.x, true)
        }

        self.reset(inputs: inputs.count)
        self.update(
            from: inputs,
            tier: self.focus,
            currency: currency,
            location: factory.state.tile,
            cache: cache,
            progressive: progressive
        )

        self.reset(outputs: factory.state.inventory.out.count)
        self.update(
            from: factory.state.inventory.out,
            currency: currency,
            location: factory.state.tile,
            cache: cache
        )

        self.terms = Term.list {
            for case (let type, let state?, let tooltip, let help) in [
                    (
                        factory.type.clerks.unit,
                        factory.clerks,
                        TooltipType.FactoryClerks,
                        TooltipType.FactoryClerksHelp
                    ),
                    (
                        factory.type.workers.unit,
                        factory.workers,
                        TooltipType.FactoryWorkers,
                        TooltipType.FactoryWorkersHelp
                    ),
                ] {
                let term: TermType = .pop(type)
                $0[term, +, tooltip: tooltip, help: help] = state.count[/3] ^^ state.change
            }
        }

        self.costs = factory.cashFlow.chart(rules: cache.rules)


        switch factory.state.budget {
        case .active(let budget)?:
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()

        default:
            self.budget = nil
        }
    }

    mutating func update(from building: BuildingSnapshot, in cache: borrowing GameUI.Cache) {
        let currency: CurrencyID = building.region.currency.id
        self.tiers = [
            .init(id: .l, label: "Operations", value: building.state.z.fl),
            .init(id: .e, label: "Maintenance", value: building.state.z.fe),
            .init(id: .x, label: "Development", value: building.state.z.fx),
        ]

        let progressive: Bool
        let inputs: ResourceInputs

        switch self.focus {
        case .l: (inputs, progressive) = (building.state.inventory.l, false)
        case .e: (inputs, progressive) = (building.state.inventory.e, false)
        case .x: (inputs, progressive) = (building.state.inventory.x, true)
        }

        self.reset(inputs: inputs.count)
        self.update(
            from: inputs,
            tier: self.focus,
            currency: currency,
            location: building.state.tile,
            cache: cache,
            progressive: progressive
        )

        self.reset(outputs: building.state.inventory.out.count)
        self.update(
            from: building.state.inventory.out,
            currency: currency,
            location: building.state.tile,
            cache: cache
        )

        self.terms = Term.list {
            let Δ: TurnDelta<Building.Dimensions> = building.state.Δ
            $0[.buildingsActive, +, tooltip: .BuildingActive, help: .BuildingActiveHelp] = Δ.active[/3]
            $0[.buildingsVacant, -, tooltip: .BuildingVacant, help: .BuildingVacantHelp] = Δ.vacant[/3]
        }

        self.costs = building.stats.cashFlow.chart(rules: cache.rules)
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
        cache: borrowing GameUI.Cache,
        progressive: Bool
    ) {
        for (id, input): (Resource, ResourceInput) in inputs.tradeable {
            let market: WorldMarket.State? = cache.markets.tradeable[id / currency]?.state
            self.needs.append(
                progressive ? .progressive(
                    label: cache.rules.resources[id].label,
                    tier: tier,
                    input: input,
                    price: market?.history.last?.prices,
                ) : .continuous(
                    label: cache.rules.resources[id].label,
                    tier: tier,
                    input: input,
                    price: market?.history.last?.prices,
                )
            )
        }
        for (id, input): (Resource, ResourceInput) in inputs.segmented {
            let market: LocalMarket? = cache.markets.segmented[id / location]
            self.needs.append(
                progressive ? .progressive(
                    label: cache.rules.resources[id].label,
                    tier: tier,
                    input: input,
                    price: market?.price,
                ) : .continuous(
                    label: cache.rules.resources[id].label,
                    tier: tier,
                    input: input,
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
        cache: borrowing GameUI.Cache,
    ) {
        for (id, output): (Resource, ResourceOutput) in outputs.tradeable {
            let market: WorldMarket.State? = cache.markets.tradeable[id / currency]?.state
            self.sales.append(
                ResourceSale.init(
                    label: cache.rules.resources[output.id].label,
                    mine: mine,
                    name: name,
                    unitsSold: output.unitsSold,
                    price: market?.history.last?.prices
                )
            )
        }
        for (id, output): (Resource, ResourceOutput) in outputs.segmented {
            let market: LocalMarket? = cache.markets.segmented[id / location]
            self.sales.append(
                ResourceSale.init(
                    label: cache.rules.resources[output.id].label,
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
