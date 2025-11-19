import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameUI
import HexGrids
import OrderedCollections

@dynamicMemberLookup struct GameSnapshot: ~Copyable {
    let context: GameContext
    let markets: (
        tradeable: OrderedDictionary<BlocMarket.ID, BlocMarket>,
        inelastic: OrderedDictionary<LocalMarket.ID, LocalMarket>
    )
    let bank: Bank
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

        let account: Bank.Account = self.bank[account: .factory(id)]
        let profit: ProfitMargins = factory.profit
        let liquid: TurnDelta<Int64> = account.Δ
        let assets: TurnDelta<Int64> = factory.Δ.vl + factory.Δ.ve + factory.Δ.vx
        let valuation: TurnDelta<Int64> = liquid + assets

        return .instructions {
            $0["Total valuation", +] = valuation[/3]
            $0[>] {
                $0["Today’s profit", +] = +profit.operating[/3]
                $0["Gross margin", +] = profit.grossMargin.map {
                    (Double.init($0))[%2]
                }
                $0["Operating margin", +] = profit.operatingMargin.map {
                    (Double.init($0))[%2]
                }
            }

            $0["Illiquid assets", +] = assets[/3]
            $0["Liquid assets", +] = liquid[/3]
            $0[>] {
                $0["Market spending", +] = +account.b[/3]
                // $0["Market spending (amortized)", +] = +?(account.b + factory.Δ.vi.value)[/3]
                $0["Market earnings", +] = +?account.r[/3]
                $0["Subsidies", +] = +?account.s[/3]
                $0["Salaries", +] = +?factory.spending.salaries[/3]
                $0["Wages", +] = +?factory.spending.wages[/3]
                $0["Interest and dividends", +] = +?factory.spending.dividend[/3]
                $0["Stock buybacks", +] = factory.spending.buybacks[/3]
                if account.e > 0 {
                    $0["Market capitalization", +] = +account.e[/3]
                }
                // $0["Capital expenditures", +] = +?account.v[/3]
            }
        }
    }

    func tooltipFactoryNeeds(
        _ id: FactoryID,
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipNeeds(tier)
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
                tier: factory.type.materials,
                details: factory.explainNeeds(_:base:)
            )
        case .e(let resource):
            return factory.state.inventory.e.tooltipDemand(
                resource,
                tier: factory.type.corporate,
                details: factory.explainNeeds(_:base:)
            )
        case .x(let resource):
            return factory.state.inventory.x.tooltipDemand(
                resource,
                tier: factory.type.expansion,
                details: factory.explainNeeds(_:x:)
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
                $0[>] = "\(tile.terrain.title) (\(tile.geology.title))"

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

        let account: Bank.Account = self.bank[account: .pop(id)]
        let liquid: TurnDelta<Int64> = account.Δ
        let assets: TurnDelta<Int64> = pop.Δ.vl + pop.Δ.ve + pop.Δ.vx
        let valuation: TurnDelta<Int64> = liquid + assets

        return .instructions {
            if case .Ward = pop.type.stratum {
                let profit: ProfitMargins = pop.profit
                $0["Total valuation", +] = valuation[/3]
                $0[>] {
                    $0["Today’s profit", +] = +profit.operating[/3]
                    $0["Gross margin", +] = profit.grossMargin.map {
                        (Double.init($0))[%2]
                    }
                    $0["Operating margin", +] = profit.operatingMargin.map {
                        (Double.init($0))[%2]
                    }
                }
            }

            $0["Illiquid assets", +] = assets[/3]
            $0["Liquid assets", +] = liquid[/3]
            $0[>] {
                $0["Welfare", +] = +?account.s[/3]
                $0[pop.type.earnings, +] = +?account.r[/3]
                $0["Interest and dividends", +] = +?account.i[/3]

                $0["Market spending", +] = +?account.b[/3]
                $0["Stock sales", +] = +?account.j[/3]
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
                self.context.factories[$0]?.type.title ?? "Unknown"
            }
        }
        if !pop.state.mines.isEmpty {
            return self.tooltipPopJobs(list: pop.state.mines.values.elements) {
                self.context.mines[$0]?.type.title ?? "Unknown"
            }
        } else {
            let employment: Int64 = pop.stats.employedBeforeEgress
            return .instructions {
                $0["Total employment"] = employment[/3]
                for output: ResourceOutput in pop.state.inventory.out.inelastic.values {
                    let name: String? = self.context.rules.resources[output.id]?.title
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
        self.context.pops[id]?.tooltipNeeds(tier)
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
                details: pop.explainNeeds(_:l:)
            )
        case .e(let resource):
            return pop.state.inventory.e.tooltipDemand(
                resource,
                tier: pop.type.e,
                details: pop.explainNeeds(_:e:)
            )
        case .x(let resource):
            return pop.state.inventory.x.tooltipDemand(
                resource,
                tier: pop.type.x,
                details: pop.explainNeeds(_:x:)
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
            let mine: MineContext = self.context.mines[id.mine],
            let tile: PlanetGrid.Tile = self.context.planets[mine.state.tile] else {
                return nil
            }
            return .instructions {
                $0[mine.type.miner.plural, +] = mine.miners.count[/3] / mine.miners.limit
                $0["Today’s change", +] = mine.miners.count[/3] <- mine.miners.before
                $0[>] {
                    // only elide fired, it’s annoying when the lines below jump around
                    $0["Hired", +] = +mine.miners.hired[/3]
                    $0["Fired", -] = +?mine.miners.fired[/3]
                    $0["Quit", -] = +mine.miners.quit[/3]
                }
                if  mine.type.decay {
                    $0["Estimated deposits"] = mine.state.Δ.size[/3]
                    $0[>] {
                        $0["Estimated yield", (+)] = mine.state.Δ.yield[..2]
                    }
                    if  let yieldRank: Int = mine.state.z.yieldRank,
                        let (chance, spawn): (Fraction, SpawnWeight) = mine.type.chance(
                            size: mine.state.z.size,
                            tile: tile.geology.id,
                            yieldRank: yieldRank
                        ),
                        let miners: PopulationStats.Row = tile.properties?.pops.type[.Miner],
                        let fromWorkers: Fraction = miners.mineExpansionFactor {
                        let fromDeposit: Double = .init(
                            mine.type.scale %/ (mine.type.scale + mine.state.z.size)
                        )
                        let fromWorkers: Double = .init(fromWorkers)
                        let fromRank: Double = MineMetadata.yieldRankExpansionFactor(
                            yieldRank
                        ).map(
                            Double.init(_:)
                        ) ?? 0.0
                        let chance: Double = Double.init(chance) * fromWorkers
                        $0["Chance to expand mine", (+)] = chance[%2]
                        $0[>] {
                            $0["Base"] = spawn.rate.value[%]
                            $0["From yield rank", (+)] = (fromRank - 1)[%0]
                            $0["From size of deposit", (+)] = (fromDeposit - 1)[%2]
                            $0["From unemployed miners", (+)] = fromWorkers[%2]
                        }
                    }
                    if  let expanded: Mine.Expansion = mine.state.last {
                        $0[>] = """
                        We recently discovered a deposit of size \(em: expanded.size[/3]) on \
                        \(em: expanded.date[.phrasal_US])
                        """
                    }
                }

                $0[>] = "\(mine.type.title)"
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
            ? .init(Double.init(pop.state.z.size) * promotion.output * 30)
            : 0
        let demotions: Int64 = demotion.output > 0
            ? .init(Double.init(pop.state.z.size) * demotion.output * 30)
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
