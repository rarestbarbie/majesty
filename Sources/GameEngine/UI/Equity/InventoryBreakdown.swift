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
    mutating func update(from pop: PopSnapshot, in cache: borrowing GameUI.Cache) {
        let currency: CurrencyID = pop.region.currency.id
        self.tiers = [
            .init(id: .l, label: "Subsistence", value: pop.z.fl),
            .init(id: .e, label: "Everyday", value: pop.z.fe),
            .init(id: .x, label: "Luxury", value: pop.z.fx),
        ]

        self.update(
            from: pop.inventory.consumption { self.focus ~= $0 },
            tier: self.focus,
            currency: currency,
            location: pop.tile,
            cache: cache,
            progressive: false
        )
        self.update(
            from: pop.inventory.production(),
            currency: currency,
            location: pop.tile,
            cache: cache
        )

        self.terms = Term.list {
            guard case .Ward = pop.type.stratum else {
                return
            }

            $0[.active, +, tooltip: .PopActive, help: .PopActiveHelp] = pop.Δ.active[/3]
            $0[.vacant, -, tooltip: .PopVacant, help: .PopVacantHelp] = pop.Δ.vacant[/3]
            $0[.profit, +, tooltip: nil, help: nil] = +pop.stats.profit.π[%1]
        }

        self.costs = pop.stats.cashFlow.chart(rules: cache.rules)
        if  let budget: Pop.Budget = pop.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            self.budget = statement.chart()
        } else {
            self.budget = nil
        }
    }

    mutating func update(from factory: FactorySnapshot, in cache: borrowing GameUI.Cache) {
        let currency: CurrencyID = factory.region.currency.id

        self.tiers = [
            .init(id: .l, label: "Materials", value: factory.z.fl),
            .init(id: .e, label: "Corporate", value: factory.z.fe),
            .init(id: .x, label: "Expansion", value: factory.z.fx),
        ]

        let progressive: Bool
        switch self.focus {
        case .l: progressive = false
        case .e: progressive = false
        case .x: progressive = true
        }

        self.update(
            from: factory.inventory.consumption { self.focus ~= $0 },
            tier: self.focus,
            currency: currency,
            location: factory.tile,
            cache: cache,
            progressive: progressive
        )
        self.update(
            from: factory.inventory.production(),
            currency: currency,
            location: factory.tile,
            cache: cache
        )

        self.terms = Term.list {
            for case (let type, let state?, let tooltip, let help) in [
                    (
                        factory.metadata.clerks.unit,
                        factory.clerks,
                        TooltipType.FactoryClerks,
                        TooltipType.FactoryClerksHelp
                    ),
                    (
                        factory.metadata.workers.unit,
                        factory.workers,
                        TooltipType.FactoryWorkers,
                        TooltipType.FactoryWorkersHelp
                    ),
                ] {
                let term: TermType = .pop(type)
                $0[term, +, tooltip: tooltip, help: help] = state.count[/3] ^^ state.change
            }
        }

        self.costs = factory.stats.cashFlow.chart(rules: cache.rules)


        switch factory.budget {
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
            .init(id: .l, label: "Operations", value: building.z.fl),
            .init(id: .e, label: "Maintenance", value: building.z.fe),
            .init(id: .x, label: "Development", value: building.z.fx),
        ]

        let progressive: Bool
        switch self.focus {
        case .l: progressive = false
        case .e: progressive = false
        case .x: progressive = true
        }

        self.update(
            from: building.inventory.consumption { self.focus ~= $0 },
            tier: self.focus,
            currency: currency,
            location: building.tile,
            cache: cache,
            progressive: progressive
        )
        self.update(
            from: building.inventory.production(),
            currency: currency,
            location: building.tile,
            cache: cache
        )

        self.terms = Term.list {
            let Δ: Delta<Building.Dimensions> = building.Δ
            $0[.active, +, tooltip: .BuildingActive, help: .BuildingActiveHelp] = Δ.active[/3]
            $0[.vacant, -, tooltip: .BuildingVacant, help: .BuildingVacantHelp] = Δ.vacant[/3]
            $0[.profit, +, tooltip: nil, help: nil] = +building.stats.profit.π[%1]
        }

        self.costs = building.stats.cashFlow.chart(rules: cache.rules)
        self.budget = building.budget.map {
            let statement: CashAllocationStatement = .init(from: $0)
            return statement.chart()
        } ?? nil
    }
}
extension InventoryBreakdown {
    private mutating func update(
        from inputs: [InventorySnapshot.Consumed],
        tier: ResourceTierIdentifier,
        currency: CurrencyID,
        location: Address,
        cache: borrowing GameUI.Cache,
        progressive: Bool
    ) {
        self.needs.removeAll(keepingCapacity: true)
        self.needs.reserveCapacity(inputs.count)

        for consumed: InventorySnapshot.Consumed in inputs {
            let id: Resource = consumed.input.id
            let price: Candle<Double>?
            if  consumed.tradeable {
                let market: WorldMarket.State? = cache.worldMarkets[id / currency]?.state
                price = market?.history.last?.prices
            } else {
                let market: LocalMarket? = cache.localMarkets[id / location]
                price = market?.price
            }

            let label: ResourceLabel = cache.rules.resources[id].label
            self.needs.append(
                progressive ? .progressive(
                    label: label,
                    tier: tier,
                    input: consumed.input,
                    price: price,
                ) : .continuous(
                    label: label,
                    tier: tier,
                    input: consumed.input,
                    price: price,
                )
            )
        }
    }

    private mutating func update(
        from outputs: [InventorySnapshot.Produced],
        currency: CurrencyID,
        location: Address,
        cache: borrowing GameUI.Cache,
    ) {
        self.sales.removeAll(keepingCapacity: true)
        self.sales.reserveCapacity(outputs.count)

        for produced: InventorySnapshot.Produced in outputs {
            let id: Resource = produced.output.id
            let price: Candle<Double>?
            if  produced.tradeable {
                let market: WorldMarket.State? = cache.worldMarkets[id / currency]?.state
                price = market?.history.last?.prices
            } else {
                let market: LocalMarket? = cache.localMarkets[id / location]
                price = market?.price
            }
            self.sales.append(
                ResourceSale.init(
                    label: cache.rules.resources[id].label,
                    mine: produced.origin,
                    name: produced.origin.map { cache.mines[$0]?.metadata.title } ?? nil,
                    unitsSold: produced.output.unitsSold,
                    price: price
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
