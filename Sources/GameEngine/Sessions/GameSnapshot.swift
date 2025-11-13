import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameUI
import HexGrids
import OrderedCollections

@dynamicMemberLookup struct GameSnapshot: ~Copyable {
    let context: GameContext
    let markets: (
        tradeable: OrderedDictionary<BlocMarket.ID, BlocMarket>,
        inelastic: OrderedDictionary<LocalMarket.ID, LocalMarket>
    )
    let date: GameDate
}
extension GameSnapshot {
    var player: CountryProperties {
        guard
        let player: CountryContext = self.countries[self.context.player] else {
            fatalError("player country does not exist in snapshot!")
        }
        return player.properties
    }
}
extension GameSnapshot {
    subscript<T>(dynamicMember keyPath: KeyPath<GameContext, T>) -> T {
        self.context[keyPath: keyPath]
    }
}
extension GameSnapshot {
    func tooltipFactoryAccount(_ id: FactoryID) -> Tooltip? {
        guard let factory: Factory = self.context.factories.state[id] else {
            return nil
        }

        let account: Bank.Account = factory.inventory.account
        let y: Factory.Dimensions = factory.yesterday
        let t: Factory.Dimensions = factory.today

        let liquid: (y: Int64, t: Int64) = (account.liq, account.balance)
        let assets: (y: Int64, t: Int64) = (y.vi + y.vx, t.vi + t.vx)
        let value: (y: Int64, t: Int64) = (liquid.y + assets.y, liquid.t + assets.t)

        let operatingProfit: Int64 = factory.operatingProfit
        let operatingMargin: Fraction? = factory.operatingMargin
        let grossMargin: Fraction? = factory.grossMargin

        return .instructions {
            $0["Total valuation", +] = value.t[/3] <- value.y
            $0[>] {
                $0["Today’s profit", +] = +operatingProfit[/3]
                $0["Gross margin", +] = grossMargin.map {
                    (Double.init($0))[%2]
                }
                $0["Operating margin", +] = operatingMargin.map {
                    (Double.init($0))[%2]
                }
            }

            $0["Illiquid assets", +] = assets.t[/3] <- assets.y
            $0[>] {
                $0["Stockpiled inputs", +] = t.vi[/3] <- y.vi
                $0["Stockpiled equipment", +] = t.vx[/3] <- y.vx
            }

            $0["Liquid assets", +] = liquid.t[/3] <- liquid.y
            $0[>] {
                $0["Market spending", +] = +account.b[/3]
                $0["Market spending (amortized)", +] = +?(account.b + factory.Δ.vi)[/3]
                $0["Market earnings", +] = +?account.r[/3]
                $0["Subsidies", +] = +?account.s[/3]
                $0["Salaries", +] = +?account.c[/3]
                $0["Wages", +] = +?account.w[/3]
                $0["Interest and dividends", +] = +?account.i[/3]
                if account.e < 0 {
                    $0["Stock buybacks", +] = account.e[/3]
                } else {
                    $0["Market capitalization", +] = +?account.e[/3]
                }
                $0["Capital expenditures", +] = +?account.v[/3]
            }
        }
    }

    func tooltipFactoryResourceIO(
        _ id: FactoryID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        switch line {
        case .l(let resource):
            return factory.state.inventory.l.tooltipDemand(
                resource,
                tier: factory.type.inputs,
                unit: "worker",
                factor: 1,
                productivity: Double.init(factory.productivity)
            )
        case .e(let resource):
            return factory.state.inventory.e.tooltipDemand(
                resource,
                tier: factory.type.office,
                unit: "worker",
                factor: 1,
                productivity: Double.init(factory.productivity)
            )
        case .x(let resource):
            return factory.state.inventory.x.tooltipDemand(
                resource,
                tier: factory.type.costs,
                unit: "level",
                factor: 1,
                productivity: Double.init(factory.productivity)
            )

        case .o(let resource):
            return factory.state.inventory.out.tooltipSupply(
                resource,
                tier: factory.type.output,
                details: factory.explainProduction(_:base:)
            )

        case .m:
            return nil
        }
    }

    func tooltipFactoryStockpile(
        _ id: FactoryID,
        _ resource: InventoryLine,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: CountryProperties = factory.region?.occupiedBy else {
            return nil
        }

        switch resource {
        case .l(let id): return factory.state.inventory.l.tooltipStockpile(id, country: country)
        case .e(let id): return factory.state.inventory.e.tooltipStockpile(id, country: country)
        case .x(let id): return factory.state.inventory.x.tooltipStockpile(id, country: country)
        case .o: return nil
        case .m: return nil
        }
    }

    func tooltipFactoryExplainPrice(
        _ id: FactoryID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: CountryProperties = factory.region?.occupiedBy else {
            return nil
        }

        let market: (
            inelastic: LocalMarket.State?,
            tradeable: BlocMarket.State?
        ) = (
            self.markets.inelastic[line.resource / factory.state.tile]?.state,
            self.markets.tradeable[line.resource / country.currency.id]?.state
        )

        switch line {
        case .l(let id): return factory.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id): return factory.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id): return factory.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id): return factory.state.inventory.out.tooltipExplainPrice(id, market)
        case .m: return nil
        }
    }

    func tooltipFactorySize(_ id: FactoryID) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }
        return .instructions {
            $0["Effective size"] = factory.state.size.area?[/3]
            $0["Growth progress"] = factory.state.size.growthProgress[/0]
                / Factory.Size.growthRequired

            if  let liquidation: FactoryLiquidation = factory.state.liquidation {
                let shareCount: Int64 = factory.equity.shareCount
                $0[>] = """
                This factory has been in bankruptcy proceedings since \
                \(em: liquidation.started[.phrasal_US]) and there \(
                    shareCount == 1 ? "is" : "are"
                ) \(neg: shareCount) \(
                    shareCount == 1 ? "share" : "shares"
                ) left to liquidate
                """
            } else {
                $0[>] = """
                Doubling the factory level will quadruple its capacity
                """
            }
        }
    }

    func tooltipFactoryWorkers(
        _ id: FactoryID,
        _ stratum: PopStratum,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        let workforce: Workforce
        let type: PopType

        if case .Worker = stratum,
            let workers: Workforce = factory.workers {
            workforce = workers
            type = factory.type.workers.unit
        } else if
            let clerks: Workforce = factory.clerks,
            let clerkTeam: Quantity<PopType> = factory.type.clerks {
            workforce = clerks
            type = clerkTeam.unit
        } else {
            return nil
        }

        return .instructions {
            $0[type.plural] = workforce.count[/3] / workforce.limit

            $0["Today’s change", +] = +?(
                workforce.hired - workforce.fired - workforce.quit
            )[/3]

            $0[>] {
                $0["Hired", +] = +?workforce.hired[/3]
                $0["Fired", +] = ??(-workforce.fired)[/3]
                $0["Quit", +] = ??(-workforce.quit)[/3]
            }
        }
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
        culture: String,
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipOwnership(
            culture: culture,
            context: self.context
        )
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
        country: CountryID,
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipOwnership(
            country: country,
            context: self.context
        )
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipOwnership()
    }

    func tooltipFactoryCashFlowItem(
        _ id: FactoryID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.factories[id]?.cashFlow.tooltip(
            rules: self.context.rules,
            item: item
        )
    }

    func tooltipFactoryBudgetItem(
        _ id: FactoryID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        switch self.context.factories[id]?.budget {
        case .active(let budget)?:
            let statement: CashAllocationStatement = .init(from: budget)
            return statement.tooltip(item: item)

        default:
            return nil
        }
    }
}
extension GameSnapshot {
    func tooltipPlanetCell(
        _ id: PlanetID,
        _ cell: HexCoordinate,
        _ layer: MinimapLayer,
    ) -> Tooltip? {
        guard
        let planet: PlanetContext = self.context.planets[id],
        let tile: PlanetGrid.Tile = planet.grid.tiles[cell],
        let pops: PopulationStats = tile.properties?.pops else {
            return nil
        }

        return .instructions(style: .borderless) {
            switch layer {
            case .Terrain:
                $0[>] = "\(tile.terrain.name) (\(tile.geology.name))"

            case .Population:
                $0["Population"] = pops.free.total[/3]
                $0[>] {
                    $0["Free"] = pops.free.total[/3]
                    $0["Enslaved"] = ??pops.enslaved.total[/3]
                }

            case .AverageMilitancy:
                let (free, _): (Double, of: Double) = pops.free.mil
                $0["Average militancy"] = free[..2]
                let enslaved: (average: Double, of: Double) = pops.enslaved.mil
                if  enslaved.of > 0 {
                    $0[>] = """
                    The average militancy of the slave population is \(
                        enslaved.average[..2],
                        style: enslaved.average > 1.0 ? .neg : .em
                    )
                    """
                }
            case .AverageConsciousness:
                let (free, _): (Double, of: Double) = pops.free.con
                $0["Average consciousness"] = free[..2]
                let enslaved: (average: Double, of: Double) = pops.enslaved.con
                if  enslaved.of > 0 {
                    $0[>] = """
                    The average consciousness of the slave population is \(
                        enslaved.average[..2],
                        style: enslaved.average > 1.0 ? .neg : .em
                    )
                    """
                }
            }

            if let name: String = tile.name {
                $0[>] = "\(name)"
            }
        }
    }
}
extension GameSnapshot {
    func tooltipPopAccount(_ id: PopID) -> Tooltip? {
        guard let pop: Pop = self.context.pops.state[id] else {
            return nil
        }

        let account: Bank.Account = pop.inventory.account
        let liquid: (y: Int64, t: Int64) = (account.liq, account.balance)
        let assets: (y: Int64, t: Int64) = (pop.yesterday.vi, pop.today.vi)
        let value: (y: Int64, t: Int64) = (liquid.y + assets.y, liquid.t + assets.t)

        return .instructions {
            if case .Ward = pop.type.stratum {
                let operatingProfit: Int64 = pop.operatingProfit
                let operatingMargin: Fraction? = pop.operatingMargin
                let grossMargin: Fraction? = pop.grossMargin
                $0["Total valuation", +] = value.t[/3] <- value.y
                $0[>] {
                    $0["Today’s profit", +] = +operatingProfit[/3]
                    $0["Gross margin", +] = grossMargin.map {
                        (Double.init($0))[%2]
                    }
                    $0["Operating margin", +] = operatingMargin.map {
                        (Double.init($0))[%2]
                    }
                }
            }

            $0["Illiquid assets", +] = assets.t[/3] <- assets.y

            $0["Liquid assets", +] = account.balance[/3] <- account.liq
            $0[>] {
                $0["Market earnings", +] = +?account.r[/3]
                $0["Welfare", +] = +?account.s[/3]
                $0["Salaries", +] = +?account.c[/3]
                $0["Wages", +] = +?account.w[/3]
                $0["Interest and dividends", +] = +?account.i[/3]

                $0["Market spending", +] = +?account.b[/3]
                $0["Stock sales", +] = +?account.v[/3]
                if case .Ward = pop.type.stratum {
                    $0["Loans taken", +] = +?account.e[/3]
                } else {
                    $0["Investments", +] = +?account.e[/3]
                }

                $0["Inheritances", +] = +?account.d[/3]
            }
        }
    }

    func tooltipPopJobs(_ id: PopID) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        if !pop.state.factories.isEmpty {
            return self.tooltipPopJobs(list: pop.state.factories.values.elements) {
                self.context.factories[$0]?.type.name ?? "Unknown"
            }
        }
        if !pop.state.mines.isEmpty {
            return self.tooltipPopJobs(list: pop.state.mines.values.elements) {
                self.context.mines[$0]?.type.name ?? "Unknown"
            }
        } else {
            let employment: Int64 = pop.state.today.size > 0 ? .init(
                (pop.unemployment * Double.init(pop.state.today.size)).rounded()
            ) : 0
            return .instructions {
                $0["Total employment"] = employment[/3]
                for output: ResourceOutput<Never> in pop.state.inventory.out.inelastic.values {
                    let name: String? = self.context.rules.resources[output.id]?.name
                    $0[>] = """
                    Today these \(pop.state.type.plural) sold \(
                        output.unitsSold[/3],
                        style: output.unitsSold < output.units.added ? .neg : .pos
                    ) of \
                    \(em: output.units.added[/3]) \(name ?? "?") produced
                    """
                }
            }
        }
    }
    private func tooltipPopJobs<Job>(
        list: [Job],
        name: (Job.ID) -> String
    ) -> Tooltip where Job: PopJob {
        let total: (
            count: Int64,
            hired: Int64,
            fired: Int64,
            quit: Int64
        ) = list.reduce(into: (0, 0, 0, 0)) {
            $0.count += $1.count
            $0.hired += $1.hired
            $0.fired += $1.fired
            $0.quit += $1.quit
        }

        return .instructions {
            $0["Total employment"] = total.count[/3]
            $0[>] {
                for job: Job in list {
                    let change: Int64 = job.hired - job.fired - job.quit
                    $0[name(job.id), +] = job.count[/3] <- job.count - change
                }
            }
            $0["Today’s change", +] = +?(total.hired - total.fired - total.quit)[/3]
            $0[>] {
                $0["Hired today", +] = +?total.hired[/3]
                $0["Fired today", +] = ??(-total.fired)[/3]
                $0["Quit today", +] = ??(-total.quit)[/3]
            }
        }
    }

    func tooltipPopNeeds(
        _ id: PopID,
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        guard let pop: Pop = self.context.pops.state[id] else {
            return nil
        }
        return .instructions {
            switch tier {
            case .l:
                $0["Life needs fulfilled"] = pop.today.fl[%3]
            case .e:
                $0["Everyday needs fulfilled"] = pop.today.fe[%3]
            case .x:
                $0["Luxury needs fulfilled"] = pop.today.fx[%3]
            }
        }
    }

    func tooltipPopResourceIO(
        _ id: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        switch line {
        case .l(let resource):
            return pop.state.inventory.l.tooltipDemand(
                resource,
                tier: pop.type.l,
                unit: "capita",
                factor: 1,
                productivity: pop.state.needsPerCapita.l,
                productivityLabel: "Consciousness"
            )
        case .e(let resource):
            return pop.state.inventory.e.tooltipDemand(
                resource,
                tier: pop.type.e,
                unit: "capita",
                factor: 1,
                productivity: pop.state.needsPerCapita.e,
                productivityLabel: "Consciousness"
            )
        case .x(let resource):
            return pop.state.inventory.x.tooltipDemand(
                resource,
                tier: pop.type.x,
                unit: "capita",
                factor: 1,
                productivity: pop.state.needsPerCapita.x,
                productivityLabel: "Consciousness"
            )
        case .o(let resource):
            return pop.state.inventory.out.tooltipSupply(
                resource,
                tier: pop.type.output,
                details: pop.explainProduction(_:base:)
            )
        case .m(let id):
            guard
            let miningConditions: MiningJobConditions = pop.mines[id.mine] else {
                return nil
            }
            return pop.state.mines[id.mine]?.out.tooltipSupply(
                id.resource,
                tier: miningConditions.output,
            ) {
                pop.explainProduction(&$0, base: $1, mine: miningConditions)
            }
        }
    }

    func tooltipPopResourceOrigin(
        _ id: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        switch line {
        case .l:
            return nil
        case .e:
            return nil
        case .x:
            return nil
        case .o:
            return nil
        case .m(let id):
            guard
            let mine: MineContext = self.context.mines[id.mine] else {
                return nil
            }
            return .instructions {
                $0[mine.type.miner.plural, +] = mine.miners.count[/3] / mine.miners.limit
                $0["Today’s change", +] = mine.miners.count[/3] <- mine.miners.before
                $0[>] {
                    $0["Hired", +] = +?mine.miners.hired[/3]
                    $0["Fired", -] = +?mine.miners.fired[/3]
                    $0["Quit", -] = +?mine.miners.quit[/3]
                }
                if mine.type.decay {
                    $0["Estimated deposits"] = mine.state.today.size[/3] <- mine.state.yesterday.size
                }

                $0[>] = "\(mine.type.name)"
            }
        }
    }

    func tooltipPopStockpile(
        _ id: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[id],
        let country: CountryProperties = pop.region?.occupiedBy else {
            return nil
        }

        switch line {
        case .l(let id): return pop.state.inventory.l.tooltipStockpile(id, country: country)
        case .e(let id): return pop.state.inventory.e.tooltipStockpile(id, country: country)
        case .x(let id): return pop.state.inventory.x.tooltipStockpile(id, country: country)
        case .o: return nil
        case .m: return nil
        }
    }

    func tooltipPopExplainPrice(
        _ pop: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[pop],
        let country: CountryProperties = pop.region?.occupiedBy else {
            return nil
        }

        let resource: Resource = line.resource
        let market: (
            inelastic: LocalMarket.State?,
            tradeable: BlocMarket.State?
        ) = (
            self.markets.inelastic[resource / pop.state.tile]?.state,
            self.markets.tradeable[resource / country.currency.id]?.state
        )

        switch line {
        case .l(let id):
            return pop.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id):
            return pop.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id):
            return pop.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id):
            return pop.state.inventory.out.tooltipExplainPrice(id, market)
        case .m(let id):
            return pop.state.mines[id.mine]?.out.tooltipExplainPrice(id.resource, market)
        }
    }

    func tooltipPopType(
        _ id: PopID,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[id],
        let country: CountryProperties = pop.region?.occupiedBy else {
            return nil
        }

        let promotion: ConditionBreakdown = pop.buildPromotionMatrix(country: country)
        let demotion: ConditionBreakdown = pop.buildDemotionMatrix(country: country)

        let promotions: Int64 = promotion.output > 0
            ? .init(Double.init(pop.state.today.size) * promotion.output * 30)
            : 0
        let demotions: Int64 = demotion.output > 0
            ? .init(Double.init(pop.state.today.size) * demotion.output * 30)
            : 0

        return .conditions(
            .list(
                "We expect \(em: promotions) promotion(s) in the next month",
                breakdown: promotion
            ),
            .list(
                "We expect \(em: demotions) demotion(s) in the next month",
                breakdown: demotion
            ),
        )
    }

    func tooltipPopOwnership(
        _ id: PopID,
        culture: String,
    ) -> Tooltip? {
        self.context.pops[id]?.tooltipOwnership(
            culture: culture,
            context: self.context
        )
    }

    func tooltipPopOwnership(
        _ id: PopID,
        country: CountryID,
    ) -> Tooltip? {
        self.context.pops[id]?.tooltipOwnership(
            country: country,
            context: self.context
        )
    }

    func tooltipPopOwnership(
        _ id: PopID,
    ) -> Tooltip? {
        self.context.pops[id]?.tooltipOwnership()
    }

    func tooltipPopCashFlowItem(
        _ id: PopID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.pops[id]?.cashFlow.tooltip(rules: self.context.rules, item: item)
    }

    func tooltipPopBudgetItem(
        _ id: PopID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        if  let budget: PopBudget = self.context.pops[id]?.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            return statement.tooltip(item: item)
        } else {
            return nil
        }
    }
}
extension GameSnapshot {
    func tooltipMarketLiquidity(
        _ id: BlocMarket.ID
    ) -> Tooltip? {
        guard
        let market: BlocMarket.State = self.markets.tradeable[id]?.state,
        let last: Int = market.history.indices.last else {
            return nil
        }

        let interval: (BlocMarket.Interval, BlocMarket.Interval)
        interval.1 = market.history[last]
        interval.0 = last != market.history.startIndex
            ? market.history[market.history.index(before: last)]
            : interval.1

        let flow: (quote: Int64, base: Int64) = (
            interval.1.volume.quote.i - interval.1.volume.quote.o,
            interval.1.volume.base.i - interval.1.volume.base.o
        )

        let today: (quote: Int64, base: Int64)
        let yesterday: (quote: Int64, base: Int64)

        today.quote = market.capital.quote
        today.base = market.capital.base

        yesterday.quote = today.quote - flow.quote
        yesterday.base = today.base - flow.base

        return .instructions {
            $0["Available liquidity", +] = interval.1.liquidity[..3] <- interval.0.liquidity
            $0[>] {
                $0["Base instrument", -] = today.base[/3] <- yesterday.base
                $0["Quote instrument", +] = today.quote[/3] <- yesterday.quote
            }
        }
    }
}
extension GameSnapshot {
    func tooltipTileCulture(
        _ id: Address,
        _ culture: String,
    ) -> Tooltip? {
        self.context.planets[id]?.properties?.pops.tooltip(culture: culture)
    }
    func tooltipTilePopType(
        _ id: Address,
        _ popType: PopType,
    ) -> Tooltip? {
        self.context.planets[id]?.properties?.pops.tooltip(popType: popType)
    }
}
