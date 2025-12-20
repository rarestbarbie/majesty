import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameUI
import HexGrids

extension GameUI {
    @dynamicMemberLookup struct Cache: ~Copyable, Sendable {
        let context: CacheContext
        var pops: [PopID: PopSnapshot]
        var factories: [FactoryID: FactorySnapshot]
        var buildings: [BuildingID: BuildingSnapshot]
        var mines: [MineID: MineSnapshot]

        init(
            context: CacheContext,
            pops: [PopID: PopSnapshot] = [:],
            factories: [FactoryID: FactorySnapshot] = [:],
            buildings: [BuildingID: BuildingSnapshot] = [:],
            mines: [MineID: MineSnapshot] = [:],
        ) {
            self.context = context
            self.pops = pops
            self.factories = factories
            self.buildings = buildings
            self.mines = mines
        }
    }
}
extension GameUI.Cache {
    subscript<T>(dynamicMember keyPath: KeyPath<GameUI.CacheContext, T>) -> T {
        self.context[keyPath: keyPath]
    }

    subscript(planet id: PlanetID) -> PlanetSnapshot.Tiles? {
        guard let planet: PlanetSnapshot = self.planets[id] else {
            return nil
        }

        return .init(planet: planet, cached: self.tiles)
    }
}
extension GameUI.Cache {
    func contextMenuMinimapTile(
        _ id: PlanetID,
        _ cell: HexCoordinate,
        _ layer: MinimapLayer,
    ) -> ContextMenu? {
        guard
        let tile: PlanetGrid.TileSnapshot = self.tiles[id / cell] else {
            return nil
        }

        return .items {
            $0["Switch to Player"] {
                if  let country: CountryID = tile.governedBy {
                    $0[.SwitchToPlayer] = country
                }
            }
        }
    }
}
extension GameUI.Cache {
    func tooltipBuildingAccount(_ id: BuildingID) -> Tooltip? {
        self.buildings[id]?.tooltipAccount(self.bank[account: .building(id)])
    }
    func tooltipBuildingNeeds(
        _ id: BuildingID,
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        self.buildings[id]?.tooltipNeeds(tier)
    }
    func tooltipBuildingResourceIO(
        _ id: BuildingID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        self.buildings[id]?.tooltipResourceIO(line)
    }
    func tooltipBuildingStockpile(
        _ id: BuildingID,
        _ resource: InventoryLine,
    ) -> Tooltip? {
        self.buildings[id]?.tooltipStockpile(resource)
    }
    func tooltipBuildingExplainPrice(
        _ id: BuildingID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        (self.buildings[id]).map { self.context.tooltipExplainPrice($0, line) } ?? nil
    }
    func tooltipBuildingActive(_ id: BuildingID) -> Tooltip? {
        self.buildings[id]?.tooltipActive()
    }
    func tooltipBuildingActiveHelp(_ id: BuildingID) -> Tooltip? {
        self.buildings[id]?.tooltipActiveHelp()
    }
    func tooltipBuildingVacant(_ id: BuildingID) -> Tooltip? {
        self.buildings[id]?.tooltipVacant()
    }
    func tooltipBuildingVacantHelp(_ id: BuildingID) -> Tooltip? {
        self.buildings[id]?.tooltipVacantHelp()
    }
    func tooltipBuildingOwnership(
        _ id: BuildingID,
        culture: CultureID,
    ) -> Tooltip? {
        self.buildings[id]?.tooltipOwnership(culture: culture, context: self.context)
    }
    func tooltipBuildingOwnership(
        _ id: BuildingID,
        country: CountryID,
    ) -> Tooltip? {
        self.buildings[id]?.tooltipOwnership(country: country, context: self.context)
    }
    func tooltipBuildingOwnership(
        _ id: BuildingID,
    ) -> Tooltip? {
        self.buildings[id]?.tooltipOwnership()
    }
    func tooltipBuildingCashFlowItem(
        _ id: BuildingID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.buildings[id]?.stats.cashFlow.tooltip(rules: self.rules, item: item)
    }
    func tooltipBuildingBudgetItem(
        _ id: BuildingID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        guard let budget: Building.Budget = self.buildings[id]?.state.budget else {
            return nil
        }
        let statement: CashAllocationStatement = .init(from: budget)
        return statement.tooltip(item: item)
    }
}
extension GameUI.Cache {
    func tooltipFactoryAccount(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipAccount(self.bank[account: .factory(id)])
    }

    func tooltipFactoryWorkers(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipWorkers()
    }
    func tooltipFactoryWorkersHelp(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipWorkersHelp()
    }

    func tooltipFactoryClerks(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipClerks()
    }
    func tooltipFactoryClerksHelp(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipClerksHelp()
    }

    func tooltipFactoryNeeds(
        _ id: FactoryID,
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        self.factories[id]?.tooltipNeeds(tier)
    }

    func tooltipFactoryResourceIO(
        _ id: FactoryID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        self.factories[id]?.tooltipResourceIO(line)
    }

    func tooltipFactoryStockpile(
        _ id: FactoryID,
        _ resource: InventoryLine,
    ) -> Tooltip? {
        self.factories[id]?.tooltipStockpile(resource)
    }

    func tooltipFactoryExplainPrice(
        _ id: FactoryID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        (self.factories[id]).map { self.context.tooltipExplainPrice($0, line) } ?? nil
    }

    func tooltipFactorySize(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipSize()
    }

    func tooltipFactorySummarizeEmployees(
        _ id: FactoryID,
        _ stratum: PopStratum,
    ) -> Tooltip? {
        self.factories[id]?.tooltipSummarizeEmployees(stratum)
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
        culture: CultureID,
    ) -> Tooltip? {
        self.factories[id]?.tooltipOwnership(culture: culture, context: self.context)
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
        country: CountryID,
    ) -> Tooltip? {
        self.factories[id]?.tooltipOwnership(country: country, context: self.context)
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
    ) -> Tooltip? {
        self.factories[id]?.tooltipOwnership()
    }

    func tooltipFactoryCashFlowItem(
        _ id: FactoryID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.factories[id]?.cashFlow.tooltip(rules: self.rules, item: item)
    }

    func tooltipFactoryBudgetItem(
        _ id: FactoryID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        switch self.factories[id]?.state.budget {
        case .active(let budget)?:
            let statement: CashAllocationStatement = .init(from: budget)
            return statement.tooltip(item: item)

        default:
            return nil
        }
    }
}
extension GameUI.Cache {
    func tooltipPopAccount(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipAccount(self.bank[account: .pop(id)])
    }

    func tooltipPopActive(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipActive()
    }
    func tooltipPopActiveHelp(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipActiveHelp()
    }
    func tooltipPopVacant(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipVacant()
    }
    func tooltipPopVacantHelp(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipVacantHelp()
    }

    func tooltipPopJobs(_ id: PopID) -> Tooltip? {
        guard let pop: PopSnapshot = self.pops[id] else {
            return nil
        }

        if !pop.state.factories.isEmpty {
            return self.tooltipPopJobs(list: pop.state.factories.values.elements) {
                self.factories[$0]?.type.title ?? "Unknown"
            }
        }
        if !pop.state.mines.isEmpty {
            return self.tooltipPopJobs(list: pop.state.mines.values.elements) {
                self.mines[$0]?.type.title ?? "Unknown"
            }
        } else {
            let employment: Int64 = pop.stats.employedBeforeEgress
            return .instructions {
                $0["Total employment"] = employment[/3]
                for output: ResourceOutput in pop.state.inventory.out.segmented.values {
                    let name: String = self.rules.resources[output.id].title
                    $0[>] = """
                    Today these \(pop.state.occupation.plural) sold \(
                        output.unitsSold[/3],
                        style: output.unitsSold < output.units.added ? .neg : .pos
                    ) of \
                    \(em: output.units.added[/3]) \(name) produced
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
        self.pops[id]?.tooltipNeeds(tier)
    }

    func tooltipPopResourceIO(
        _ id: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        self.pops[id]?.tooltipResourceIO(line)
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
            let mine: MineSnapshot = self.mines[id.mine],
            let tile: PlanetGrid.TileSnapshot = self.tiles[mine.state.tile] else {
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
                            tile: tile.geology.id,
                            size: mine.state.z.size,
                            yieldRank: yieldRank
                        ),
                        let miners: PopulationStats.Row = tile.properties?.pops.occupation[.Miner],
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
                            $0["From yield rank", (+)] = +?(fromRank - 1)[%0]
                            $0["From size of deposit", (+)] = (fromDeposit - 1)[%2]
                            $0["From unemployed miners", (+)] = fromWorkers[%2]
                        }
                    }
                    if  let expanded: Mine.Expansion = mine.state.last {
                        $0[>] = """
                        We recently unearthed a deposit of size \(em: expanded.size[/3]) on \
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
        self.pops[id]?.tooltipStockpile(line)
    }

    func tooltipPopExplainPrice(
        _ pop: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        (self.pops[pop]).map { self.context.tooltipExplainPrice($0, line) } ?? nil
    }

    func tooltipPopType(
        _ id: PopID,
    ) -> Tooltip? {
        self.pops[id]?.tooltipOccupation()
    }

    func tooltipPopOwnership(
        _ id: PopID,
        culture: CultureID,
    ) -> Tooltip? {
        self.pops[id]?.tooltipOwnership(culture: culture, context: self.context)
    }

    func tooltipPopOwnership(
        _ id: PopID,
        country: CountryID,
    ) -> Tooltip? {
        self.pops[id]?.tooltipOwnership(country: country, context: self.context)
    }

    func tooltipPopOwnership(
        _ id: PopID,
    ) -> Tooltip? {
        self.pops[id]?.tooltipOwnership()
    }

    func tooltipPopCashFlowItem(
        _ id: PopID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.pops[id]?.stats.cashFlow.tooltip(rules: self.rules, item: item)
    }

    func tooltipPopBudgetItem(
        _ id: PopID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        if  let budget: Pop.Budget = self.pops[id]?.state.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            return statement.tooltip(item: item)
        } else {
            return nil
        }
    }
}

extension GameUI.Cache {
    func tooltipMarketLiquidity(
        _ id: WorldMarket.ID
    ) -> Tooltip? {
        guard
        let market: WorldMarket.State = self.markets.tradeable[id]?.state,
        let last: Int = market.history.indices.last else {
            return nil
        }

        let interval: (WorldMarket.Interval, WorldMarket.Interval)
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
extension GameUI.Cache {
    func tooltipPlanetCell(
        _ id: PlanetID,
        _ cell: HexCoordinate,
        _ layer: MinimapLayer,
    ) -> Tooltip? {
        self.tiles[id / cell]?.tooltip(layer)
    }
    func tooltipTileCulture(
        _ id: Address,
        _ culture: CultureID,
    ) -> Tooltip? {
        guard let culture: Culture = self.rules.pops.cultures[culture] else {
            return nil
        }
        return self.tiles[id]?.properties?.pops.tooltip(culture: culture)
    }
    func tooltipTilePopType(
        _ id: Address,
        _ occupation: PopOccupation,
    ) -> Tooltip? {
        self.tiles[id]?.properties?.pops.tooltip(occupation: occupation)
    }
}
