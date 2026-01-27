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
        _ id: Address,
        _ layer: PlanetMapLayer,
    ) -> ContextMenu? {
        guard
        let tile: TileSnapshot = self.tiles[id] else {
            return nil
        }

        return .items {
            $0["Switch to Player"] {
                if  let country: CountryID = tile.country?.governedBy {
                    $0[.SwitchToPlayer] = country
                }
            }
        }
    }
}
extension GameUI.Cache {
    func tooltipBuildingAccount(_ id: BuildingID) -> Tooltip? {
        self.buildings[id]?.tooltipAccount(self.bank[account: id])
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
        self.buildings[id]?.tooltipExplainPrice(line, context: self.context)
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
        gender: Gender?
    ) -> Tooltip? {
        self.buildings[id]?.tooltipOwnership(gender: gender, context: self.context)
    }
    func tooltipBuildingOwnership(
        _ id: BuildingID,
    ) -> Tooltip? {
        self.buildings[id]?.tooltipOwnership()
    }
    func tooltipBuildingCashFlowItem(
        _ id: BuildingID,
        _ item: FinancialStatement.CostItem,
    ) -> Tooltip? {
        self.buildings[id]?.stats.financial.costs.tooltip(rules: self.rules, item: item)
    }
    func tooltipBuildingBudgetItem(
        _ id: BuildingID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        guard let budget: Building.Budget = self.buildings[id]?.budget else {
            return nil
        }
        let statement: CashAllocationStatement = .init(from: budget)
        return statement.tooltip(item: item)
    }
}
extension GameUI.Cache {
    func tooltipFactoryAccount(_ id: FactoryID) -> Tooltip? {
        self.factories[id]?.tooltipAccount(self.bank[account: id])
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
        self.factories[id]?.tooltipExplainPrice(line, context: self.context)
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
        gender: Gender?
    ) -> Tooltip? {
        self.factories[id]?.tooltipOwnership(gender: gender, context: self.context)
    }

    func tooltipFactoryOwnership(
        _ id: FactoryID,
    ) -> Tooltip? {
        self.factories[id]?.tooltipOwnership()
    }

    func tooltipFactoryCashFlowItem(
        _ id: FactoryID,
        _ item: FinancialStatement.CostItem,
    ) -> Tooltip? {
        self.factories[id]?.stats.financial.costs.tooltip(rules: self.rules, item: item)
    }

    func tooltipFactoryBudgetItem(
        _ id: FactoryID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        switch self.factories[id]?.budget {
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
        self.pops[id]?.tooltipAccount(self.bank[account: id])
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
    func tooltipPopJobHelp(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipJobHelp(
            factories: self.factories,
            mines: self.mines,
            rules: self.rules
        )
    }
    func tooltipPopJobList(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipJobList(
            factories: self.factories,
            mines: self.mines,
            rules: self.rules
        )
    }
    func tooltipPopJobs(_ id: PopID) -> Tooltip? {
        self.pops[id]?.tooltipJobs(rules: self.rules)
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
            let tile: TileSnapshot = self.tiles[mine.state.tile] else {
                return nil
            }

            return tile.tooltipResourceOrigin(mine: mine, ledger: self.ledger.z)
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
        self.pops[pop]?.tooltipExplainPrice(line, context: self.context)
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
        gender: Gender?
    ) -> Tooltip? {
        self.pops[id]?.tooltipOwnership(gender: gender, context: self.context)
    }

    func tooltipPopOwnership(
        _ id: PopID,
    ) -> Tooltip? {
        self.pops[id]?.tooltipOwnership()
    }

    func tooltipPopCashFlowItem(
        _ id: PopID,
        _ item: FinancialStatement.CostItem,
    ) -> Tooltip? {
        self.pops[id]?.stats.financial.costs.tooltip(rules: self.rules, item: item)
    }

    func tooltipPopBudgetItem(
        _ id: PopID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        if  let budget: Pop.Budget = self.pops[id]?.budget {
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
        self.worldMarkets[id]?.snapshot?.tooltipLiquidity()
    }
    func tooltipMarketHistory(
        _ id: WorldMarket.ID,
        _ date: GameDate
    ) -> Tooltip? {
        self.worldMarkets[id]?.snapshot?.tooltipCandle(date, today: self.context.date)
    }
}
extension GameUI.Cache {
    func tooltipPlanetTile(
        _ id: Address,
        _ layer: PlanetMapLayer,
    ) -> Tooltip? {
        self.tiles[id]?.tooltip(layer)
    }

    func tooltipTilePopOccupation(
        _ id: Address,
        _ crosstab: PopOccupation,
    ) -> Tooltip? {
        self.tiles[id]?.tooltipPopOccupation(in: self.context, id: crosstab)
    }
    func tooltipTilePopRace(
        _ id: Address,
        _ crosstab: CultureID,
    ) -> Tooltip? {
        self.tiles[id]?.tooltipPopRace(in: self.context, id: crosstab)
    }

    func tooltipTileGDP(
        _ id: Address,
    ) -> Tooltip? {
        self.tiles[id]?.tooltipGDP(in: self.context)
    }
    func tooltipTileIndustry(
        _ id: Address,
        _ crosstab: EconomicLedger.Industry,
    ) -> Tooltip? {
        self.tiles[id]?.tooltipIndustry(in: self.context, id: crosstab)
    }
    func tooltipTileResourceProduced(
        _ id: Address,
        _ crosstab: Resource,
    ) -> Tooltip? {
        self.tiles[id]?.tooltipResourceProduced(in: self.context, id: crosstab)
    }
    func tooltipTileResourceConsumed(
        _ id: Address,
        _ crosstab: Resource,
    ) -> Tooltip? {
        self.tiles[id]?.tooltipResourceConsumed(in: self.context, id: crosstab)
    }
}
