import Assert
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameTerrain
import HexGrids
import OrderedCollections

struct GameContext {
    var player: CountryID

    private(set) var planets: RuntimeContextTable<PlanetContext>
    private(set) var tiles: RuntimeContextTable<TileContext>

    private(set) var currencies: OrderedDictionary<CurrencyID, Currency>
    private(set) var countries: RuntimeContextTable<CountryContext>
    private(set) var buildings: DynamicContextTable<BuildingContext>
    private(set) var factories: DynamicContextTable<FactoryContext>
    private(set) var mines: DynamicContextTable<MineContext>
    private(set) var pops: DynamicContextTable<PopContext>

    let symbols: GameSaveSymbols
    var rules: GameMetadata
}
extension GameContext {
    static func load(_ save: borrowing GameSave, rules: consuming GameMetadata) throws -> Self {
        let _none: _NoMetadata = .init()
        // closure captures `rules`, and calls a mutating subscript! writing these inline would
        // still be correct, due to order of evaluation, but this is much clearer
        let tiles: RuntimeContextTable<TileContext> = try .init(states: save.tiles) {
            rules.tiles[$0.type]
        }
        let pops: DynamicContextTable<PopContext> = try .init(states: save.pops) {
            rules.pops[$0.type]
        }
        return .init(
            player: save.player,
            planets: try .init(states: save.planets) { _ in _none },
            tiles: tiles,
            currencies: save.currencies.reduce(into: [:]) { $0[$1.id] = $1 },
            countries: try .init(states: save.countries) { _ in _none },
            buildings: try .init(states: save.buildings) { rules.buildings[$0.type] },
            factories: try .init(states: save.factories) { rules.factories[$0.type] },
            mines: try .init(states: save.mines) { rules.mines[$0.type] },
            pops: pops,
            symbols: save.symbols,
            rules: rules,
        )
    }

    func save(_ world: borrowing GameWorld) -> GameSave {
        .init(
            symbols: self.symbols,
            random: world.random,
            player: self.player,
            cultures: self.rules.pops.cultures.values.sorted { $0.id < $1.id },
            accounts: world.bank.accounts.items,
            localMarkets: world.localMarkets.values.map(\.state),
            worldMarkets: world.worldMarkets.values.map(\.state),
            date: world.date,
            planets: [_].init(self.planets.state),
            tiles: [_].init(self.tiles.state),
            currencies: self.currencies.values.elements,
            countries: [_].init(self.countries.state),
            buildings: [_].init(self.buildings.state),
            factories: [_].init(self.factories.state),
            mines: [_].init(self.mines.state),
            pops: [_].init(self.pops.state),
        )
    }
}
extension GameContext {
    mutating func loadTerrain(from editor: PlanetTileEditor) throws {
        let resized: Bool? = {
            if  let size: Int8 = $0?.state.size {
                $0?.state.size = editor.size
                return editor.size != size
            } else {
                return nil
            }
        }(&self.planets[editor.id.planet])

        guard
        let resized: Bool else {
            fatalError("Planet \(editor.id.planet) does not exist!!!")
        }

        // editor supports only one operation at a time
        let moved: [Tile]
        if  resized {
            // when resizing, we extract all existing tiles, and then move them, plus the new
            // tiles (any minus deleted ones) to the end of the table. this ensures they remain
            // contiguous, and prevents zombie tiles from lingering
            let template: HexGrid = .init(radius: editor.size)
            moved = try template.reduce(into: []) {
                let id: Address = editor.id.planet / $1
                let tile: Tile = try self.tiles.state[id] ?? .init(
                    id: id,
                    type: .init(
                        ecology: try self.symbols[ecology: editor.ecology],
                        geology: try self.symbols[geology: editor.geology]
                    ),
                    name: editor.name
                )

                $0.append(tile)
            }
        } else if let direction: HexRotation = editor.rotate {
            let template: HexGrid = .init(radius: editor.size)
            /// although rotations could be spatially performed in-place, in practice we still
            /// need to reload metadata, so we do the same extract-and-move strategy as when
            /// resizing the planet grid
            moved = template.reduce(into: []) {
                guard let source: Tile = self.tiles.state[editor.id.planet / $1] else {
                    return
                }

                let id: HexCoordinate = source.id.tile.rotated(direction)
                let moved: Tile = .init(
                    id: editor.id.planet / id,
                    type: source.type,
                    name: source.name
                )

                $0.append(moved)
            }
        } else {
            let type: TileType = .init(
                ecology: try self.symbols[ecology: editor.ecology],
                geology: try self.symbols[geology: editor.geology]
            )
            if  let metadata: TileMetadata = self.rules.tiles[type] {
                self.tiles[editor.id] = .init(
                    type: metadata,
                    state: .init(
                        id: editor.id,
                        type: type,
                        name: editor.name,
                    )
                )
            }

            return
        }

        try self.tiles.replace(planet: editor.id.planet, with: moved, metadata: &self.rules)
    }

    func saveTerrain() -> TerrainMap {
        let planets: [PlanetID: [Terrain]] = self.tiles.reduce(into: [:]) {
            $0[$1.state.id.planet, default: []].append($1.terrain)
        }
        return .init(
            planets: self.planets.map(\.state),
            planetSurfaces: self.planets.map {
                PlanetSurface.init(
                    id: $0.state.id,
                    size: $0.state.size,
                    grid: planets[$0.state.id] ?? []
                )
            }
        )
    }
}
extension GameContext {
    var pruningPass: PruningPass {
        .init(
            countries: self.countries.keys,
            buildings: self.buildings.keys,
            factories: self.factories.keys,
            mines: self.mines.keys,
            pops: self.pops.keys,
        )
    }

    var territoryPass: TerritoryPass {
        .init(
            player: self.player,
            planets: self.planets.state,
            countries: self.countries.state,
            factories: self.factories.state,
            mines: self.mines.state,
            pops: self.pops.state,
            rules: self.rules
        )
    }

    private var legalPass: LegalPass {
        .init(
            countries: self.countries.state,
            buildings: self.buildings.state,
            factories: self.factories.state,
            pops: self.pops.state,
        )
    }

    private var residentPass: ResidentPass {
        .init(
            player: self.player,
            planets: self.planets,
            countries: self.countries,
            buildings: self.buildings.state,
            factories: self.factories.state,
            mines: self.mines.state,
            pops: self.pops.state,
            rules: self.rules
        )
    }

    private var countryPass: CountryContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
        )
    }
    private var buildingPass: BuildingContext.ComputationPass {
        self.factoryPass
    }
    private var factoryPass: FactoryContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
            tiles: self.tiles,
        )
    }
    private var minePass: MineContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
            tiles: self.tiles,
        )
    }
    private var popPass: PopContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
            tiles: self.tiles,
            factories: self.factories.state,
            mines: self.mines.state,
        )
    }
}
extension GameContext {
    private mutating func prune(world: inout GameWorld) {
        let retain: PruningPass = self.pruningPass

        world.bank.prune(in: retain)

        for i: Int in self.buildings.indices {
            self.buildings[i].state.prune(in: retain)
        }
        for i: Int in self.factories.indices {
            self.factories[i].state.prune(in: retain)
        }
        for i: Int in self.pops.indices {
            self.pops[i].state.prune(in: retain)
        }
    }
    private mutating func index(world: borrowing GameWorld) throws -> GameLedger.Interval {
        for i: Int in self.countries.indices {
            let country: Country = self.countries.state[i]
            let authority: DiplomaticAuthority = try .compute(for: country, in: self)
            for tile: Address in country.tilesControlled {
                self.tiles[tile]?.update(authority: authority)
            }
        }

        for i: Int in self.planets.indices {
            self.planets[i].startIndexCount()
        }
        for i: Int in self.tiles.indices {
            self.tiles[i].startIndexCount()
        }

        var economy: EconomicAggregator = .init()

        for i: Int in self.buildings.indices {
            self.buildings[i].startIndexCount()
        }
        for i: Int in self.factories.indices {
            self.factories[i].startIndexCount()
        }
        for i: Int in self.mines.indices {
            self.mines[i].startIndexCount()
        }
        for i: Int in self.pops.indices {
            self.pops[i].startIndexCount()
        }
        for i: Int in self.pops.indices {
            /// avoid copy-on-write. note that we should not be accessing `PopContext.region`
            /// here — that will be stale as it is not updated until after indexing is complete
            let (pop, stats): (Pop, Pop.Stats) = { ($0.state, $0.stats) } (self.pops[i])
            let account: Bank.Account = world.bank[account: pop.id]

            guard
            let _: RegionalAuthority = self.tiles[pop.tile]?.addResidentCount(pop, stats) else {
                fatalError("Pop \(pop.id) has no home tile!!!")
            }

            for job: FactoryJob in pop.factories.values {
                self.factories[modifying: job.id].addWorkforceCount(pop: pop, job: job)
            }
            for job: MiningJob in pop.mines.values {
                self.mines[modifying: job.id].addWorkforceCount(pop: pop, job: job)
            }

            let equity: Equity<LEI>.Statistics
            if  pop.type.stratum > .Ward {
                // free pops do not have shareholders
                economy.countFree(state: pop, stats: stats, account: account)
                continue
            } else {
                /// We compute this here, and not in `PopContext.compute`, so that its global
                /// context can exclude the pop table itself, allowing us to mutate `PopContext`
                /// in-place there without individually retaining and releasing every `PopContext`
                /// in the array on every loop iteration, which would be O(n²)!
                equity = .compute(entity: pop, account: account, context: self.legalPass)
                economy.countSlave(state: pop, stats: stats, equity: equity)
            }

            self.count(asset: pop.id.lei, equity: pop.equity)
            self.pops[i].update(equityStatistics: equity)
        }
        for i: Int in self.factories.indices {
            let (factory, stats): (Factory, Factory.Stats) = {
                ($0.state, $0.stats)
            } (self.factories[i])

            guard
            let _: RegionalAuthority = self.tiles[factory.tile]?.addResidentCount(factory) else {
                fatalError("Factory \(factory.id) has no home tile!!!")
            }

            let equity: Equity<LEI>.Statistics = .compute(
                entity: factory,
                account: world.bank[account: factory.id],
                context: self.legalPass
            )

            economy.countFactory(state: factory, stats: stats, equity: equity)

            self.count(asset: factory.id.lei, equity: factory.equity)
            self.factories[i].update(equityStatistics: equity)
        }
        for i: Int in self.buildings.indices {
            let (building, stats): (Building, Building.Stats) = {
                ($0.state, $0.stats)
            } (self.buildings[i])

            guard
            let _: RegionalAuthority = self.tiles[building.tile]?.addResidentCount(
                building
            ) else {
                fatalError("Building \(building.id) has no home tile!!!")
            }

            let equity: Equity<LEI>.Statistics = .compute(
                entity: building,
                account: world.bank[account: building.id],
                context: self.legalPass
            )

            economy.countBuilding(state: building, stats: stats, equity: equity)

            self.count(asset: building.id.lei, equity: building.equity)
            self.buildings[i].update(equityStatistics: equity)
        }
        for i: Int in self.mines.indices {
            let mine: Mine = self.mines.state[i]
            let counted: ()? = self.tiles[mine.tile]?.addResidentCount(mine)

            #assert(counted != nil, "Mine \(mine.id) has no home tile!!!")
        }

        return .init(economy: economy.aggregate())
    }
}
extension GameContext {
    mutating func advance(_ turn: inout Turn) throws {
        turn.notifications.turn()
        turn.bank.turn()

        for i: Int in self.planets.indices {
            try self.planets[i].advance(turn: &turn, context: self)
        }
        for i: Int in self.tiles.indices {
            try self.tiles[i].advance(turn: &turn)
        }

        for i: Int in self.countries.indices {
            try self.countries[i].advance(turn: &turn, context: self)
        }

        turn.worldMarkets.turn()
        // need to call this first, to update prices before trading
        turn.localMarkets.turn {
            guard
            let authority: DiplomaticAuthority = self.tiles[$0.id.location]?.authority else {
                fatalError("LocalMarket \($0.id) exists in a tile with no authority!!!")
            }

            $0.turn(policy: authority.modifiers.localMarkets[$0.id.resource] ?? .default)
        }

        self.buildings.turn { $0.turn(on: &turn) }
        self.factories.turn { $0.turn(on: &turn) }
        self.mines.turn { $0.turn(on: &turn) }
        self.pops.turn { $0.turn(on: &turn) }

        turn.localMarkets.turn {
            let resource: Resource = $0.id.resource
            $0.match(random: &turn.random) {
                switch $1 {
                case .sell:
                    turn.bank[account: $0.entity].r += $0.value
                case .buy:
                    turn.bank[account: $0.entity].b -= $0.value
                }
                self.report(resource: resource, fill: $0, side: $1)
            }
        }
        turn.stockMarkets.turn {
            let shape: StockMarket.Shape = .init(r: 0.02)
            $0.match(shape: shape, random: &turn.random) {
                switch $2.asset {
                case .reserve:
                    fatalError("Central bank should not have tradeable shares!!!")

                case .building(let id):
                    self.buildings[modifying: id].state.equity.trade(
                        random: &$0,
                        bank: &turn.bank,
                        fill: $2
                    )
                case .factory(let id):
                    self.factories[modifying: id].state.equity.trade(
                        random: &$0,
                        bank: &turn.bank,
                        fill: $2
                    )
                case .pop(let id):
                    self.pops[modifying: id].state.equity.trade(
                        random: &$0,
                        bank: &turn.bank,
                        fill: $2
                    )
                }
            }
        }

        let shuffled: ResidentOrder = .randomize(
            (self.buildings, Resident.building(_:)),
            (self.factories, Resident.factory(_:)),
            (self.pops, Resident.pop(_:)),
            with: &turn.random.generator
        )

        for i: Resident in shuffled.residents {
            switch i {
            case .building(let i): self.buildings[i].transact(turn: &turn)
            case .factory(let i): self.factories[i].transact(turn: &turn)
            case .pop(let i): self.pops[i].transact(turn: &turn)
            }
        }

        turn.worldMarkets.advance()

        self.buildings.turn { $0.advance(turn: &turn) }
        self.factories.turn { $0.advance(turn: &turn) }
        self.mines.turn { $0.advance(turn: &turn) }
        self.pops.turn { $0.advance(turn: &turn) }

        let unfilled: (
            [(PopOccupation, [PopJobOfferBlock])],
            [(PopOccupation, [PopJobOfferBlock])]
        ) = self.postPopHirings(&turn, order: shuffled)
        self.postPopFirings(&turn)

        self.awardRanksToFactories([unfilled.0, unfilled.1].joined())
        self.awardRanksToMines()

        try self.executeMovements(&turn)

        self.destroyObjects()
    }

    mutating func compute(_ world: inout GameWorld) throws {
        self.prune(world: &world)

        world.ledger.y = world.ledger.z
        world.ledger.z = try self.index(world: world)
        self.count(aggregating: world.ledger.z)

        for i: Int in self.planets.indices {
            // update physical planet location, without triggering a copy-on-write
            let motion: (
                global: CelestialMotion?,
                local: CelestialMotion?
            ) = self.planets[i].state.motion(in: self.planets.state)
            ; {
                $0.motion = motion
                $0.afterIndexCount(world: world)
            } (&self.planets[i])
        }
        for i: Int in self.tiles.indices {
            self.tiles[i].afterIndexCount(world: world)
        }

        for i: Int in self.buildings.indices {
            try self.buildings[i].afterIndexCount(world: world, context: self.buildingPass)
        }
        for i: Int in self.factories.indices {
            try self.factories[i].afterIndexCount(world: world, context: self.factoryPass)
        }
        for i: Int in self.mines.indices {
            try self.mines[i].afterIndexCount(world: world, context: self.minePass)
        }
        for i: Int in self.pops.indices {
            try self.pops[i].afterIndexCount(world: world, context: self.popPass)
        }
    }
}

extension GameContext {
    private mutating func count(asset: LEI, equity: Equity<LEI>) {
        for stake: EquityStake<LEI> in equity.shares.values {
            // the pruning pass should have ensured that only valid stakes remain
            switch stake.id {
            case .reserve:
                continue

            case .building(let id):
                self.buildings[modifying: id].addPosition(asset: asset, value: stake.shares.total)
            case .factory(let id):
                self.factories[modifying: id].addPosition(asset: asset, value: stake.shares.total)
            case .pop(let id):
                self.pops[modifying: id].addPosition(asset: asset, value: stake.shares.total)
            }
        }
    }
    private mutating func count(aggregating ledger: GameLedger.Interval) {
        for (key, value): (EconomicLedger.Regional<EconomicLedger.Industry>, Int64) in ledger.economy.gdp {
            self.tiles[key.location]?.stats.gdp += value
        }
        // the gender table is incomplete, as it excludes non-natural persons, but every entity
        // in the game has a race, so we can use that to compute GNI
        for (key, value): (EconomicLedger.Regional<CultureID>, EconomicLedger.CapitalMetrics) in ledger.economy.racial {
            self.tiles[key.location]?.stats.gnp += value.income
        }
        for (key, value): (EconomicLedger.IncomeSection, EconomicLedger.IncomeMetrics) in ledger.economy.income {
            switch key.stratum {
            case .Elite:
                self.tiles[key.region]?.stats.incomeElite[key.gender.sex] += value
            case .Clerk:
                self.tiles[key.region]?.stats.incomeUpper[key.gender.sex] += value
            default:
                self.tiles[key.region]?.stats.incomeLower[key.gender.sex] += value
            }
        }
        for (key, value): (Address, EconomicLedger.SocialMetrics) in ledger.economy.slaves {
            self.tiles[key]?.stats.slaves += value
        }
    }
    private mutating func report(
        resource: Resource,
        fill: LocalMarket.Fill,
        side: LocalMarket.Side
    ) {
        switch fill.entity {
        case .reserve:
            fatalError("Central bank should not be participating in local market!!!")

        case .building(let id):
            self.buildings[modifying: id].state.inventory.report(
                resource: resource,
                fill: fill,
                side: side
            )
        case .factory(let id):
            self.factories[modifying: id].state.inventory.report(
                resource: resource,
                fill: fill,
                side: side
            )
        case .pop(let id):
            if  case .sell = side,
                case .mine(let mine)? = fill.memo {
                self.pops[modifying: id].state.mines[mine]?.out[resource]?.report(
                    unitsSold: fill.filled,
                    valueSold: fill.value,
                )
            } else {
                self.pops[modifying: id].state.inventory.report(
                    resource: resource,
                    fill: fill,
                    side: side
                )
            }
        }
    }
}
extension GameContext {
    private mutating func postPopFirings(_ turn: inout Turn) {
        var layoffs: [Turn.Jobs.Fire.Key: PopJobLayoffBlock] = turn.jobs.fire.turn()

        self.pops.turn {
            let type: PopOccupation = $0.state.occupation
            for j: Int in $0.state.factories.values.indices {
                {
                    $0.fire(&layoffs[.factory(type, $0.id)])
                } (&$0.state.factories.values[j])
            }
            for j: Int in $0.state.mines.values.indices {
                {
                    $0.fire(&layoffs[.mine(type, $0.id)])
                } (&$0.state.mines.values[j])
            }
        }
    }
    private mutating func postPopHirings(_ turn: inout Turn, order: ResidentOrder) -> (
        [(PopOccupation, [PopJobOfferBlock])],
        [(PopOccupation, [PopJobOfferBlock])]
    ) {
        let supply: LaborMarket = .index(pops: self.pops, in: order)
        return supply.match(
            region: &turn.jobs.hire.region,
            planet: &turn.jobs.hire.planet,
            random: turn.random,
            mode: .MajorityPreference
        ) {
            switch $0 {
            case .factory(let id):
                self.pops[$1].state.factories[id, default: .init(id: id)].hire($2)
            case .mine(let id):
                self.pops[$1].state.mines[id, default: .init(id: id)].hire($2)
            }
        }
    }
}
extension GameContext {
    private mutating func awardRanksToFactories(
        _ types: some Sequence<(PopOccupation, [PopJobOfferBlock])>
    ) {
        for (type, unfilled): (PopOccupation, [PopJobOfferBlock]) in types {
            let raise: Workforce.RaiseEvaluator = .init(employers: unfilled.count)
            for (i, block): (Int, PopJobOfferBlock) in unfilled.enumerated() {
                guard case .factory(let id) = block.job else {
                    continue
                }
                {
                    let pf: Int = raise.pf(position: i)
                    if type.stratum <= .Worker {
                        $0.wf = pf
                    } else {
                        $0.cf = pf
                    }
                } (&self.factories[modifying: id].state.z)
            }
        }
    }
    private mutating func awardRanksToMines() {
        for tile: TileContext in self.tiles {
            var ranks: [PopOccupation: [(id: MineID, yield: Double)]] = [:]
            for mine: MineID in tile.mines {
                guard
                let mine: MineContext = self.mines[mine] else {
                    continue
                }

                ranks[mine.type.miner, default: []].append(
                    (id: mine.state.id, yield: mine.state.z.yield)
                )
            }
            for var mines: [(id: MineID, yield: Double)] in ranks.values {
                mines.sort { $0.yield > $1.yield }
                for (yieldRank, (id, _)): (Int, (MineID, _)) in mines.enumerated() {
                    self.mines[modifying: id].state.z.yieldRank = yieldRank
                }
            }
        }
    }
}
extension GameContext {
    private mutating func executeMovements(_ turn: inout Turn) throws {
        try self.executeConversions(&turn)
        try self.executeConstructions(&turn)
    }
    private mutating func executeConversions(_ turn: inout Turn) throws {
        defer {
            turn.conversions.removeAll(keepingCapacity: true)
        }

        // let investments: (
        //     stocks: [PopID: [FactoryID]],
        //     slaves: [PopID: [PopID]]
        // ) = (
        //     self.factories.state.reduce(into: [:]) {
        //         for stake: EquityStake<LEI> in $1.equity.shares.values {
        //             if case .pop(let id) = stake.id {
        //                 $0[id, default: []].append($1.id)
        //             }
        //         }
        //     },
        //     self.pops.table.state.reduce(into: [:]) {
        //         for stake: EquityStake<LEI> in $1.equity.shares.values {
        //             if case .pop(let id) = stake.id {
        //                 $0[id, default: []].append($1.id)
        //             }
        //         }
        //     }
        // )

        for conversion: Pop.Conversion in turn.conversions {
            let inheritedCash: Int64 = turn.bank[account: .pop(conversion.from)].inherit(
                fraction: conversion.inherits
            )
            let inherited: (mil: Double, con: Double) = {
                (
                    $0.state.z.mil,
                    $0.state.z.con
                )
            } (&self.pops[modifying: conversion.from])

            // TODO: pops should also inherit stock portfolios and slaves

            let target: PopID = try self.pops[conversion.to] {
                self.rules.pops[$0.type]
            } update: {
                let weight: Fraction.Interpolator<Double> = .init(
                    conversion.size %/ (conversion.size + $1.z.total)
                )

                $1.z.active += conversion.size
                $1.z.mil = weight.mix(inherited.mil, $1.z.mil)
                $1.z.con = weight.mix(inherited.con, $1.z.con)
                return $1.id
            }

            turn.bank[account: target].d += inheritedCash
        }
    }
    private mutating func executeConstructions(_ turn: inout Turn) throws {
        for i: Int in self.tiles.indices {
            let (building, factory, mine, tile): (
                BuildingMetadata?,
                FactoryMetadata?,
                (type: MineMetadata, size: Int64)?,
                Address
            ) = {
                let building: BuildingMetadata? = $0.pickBuilding(
                    among: self.rules.buildings,
                    using: &turn.random
                )
                let factory: FactoryMetadata? = $0.pickFactory(
                    among: self.rules.factories,
                    using: &turn.random
                )
                let mine: (type: MineMetadata, size: Int64)? = $0.pickMine(
                    among: self.rules.mines,
                    turn: &turn
                )
                return (building, factory, mine, tile: $0.id)
            } (&self.tiles[i])

            if  let type: BuildingMetadata = building {
                let building: Building.Section = .init(type: type.id, tile: tile)
                try self.buildings[building] {
                    _ in
                    type
                } update: {
                    $1.z.active = 1
                }
            }

            if  let type: FactoryMetadata = factory {
                let factory: Factory.Section = .init(type: type.id, tile: tile)
                try self.factories[factory] {
                    _ in
                    type
                } update: {
                    $1.size = .init(level: 0)
                }
            }

            if  let (type, size): (MineMetadata, Int64) = mine {
                let mine: Mine.Section = .init(type: type.id, tile: tile)
                try self.mines[mine] {
                    _ in
                    type
                } update: {
                    $1.z.size += size
                    $1.last = Mine.Expansion.init(size: size, date: turn.date)
                }
            }
        }
    }
}
extension GameContext {
    private mutating func destroyObjects() {
        self.buildings.lint()
        self.factories.lint()
        self.mines.lint()
        self.pops.lint()
    }
}
