import Assert
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameTerrain
import JavaScriptKit

struct GameContext {
    var player: CountryID

    private(set) var planets: RuntimeContextTable<PlanetContext>
    private(set) var cultures: RuntimeContextTable<CultureContext>
    private(set) var countries: RuntimeContextTable<CountryContext>
    private(set) var factories: DynamicContextTable<FactoryContext>
    private(set) var mines: DynamicContextTable<MineContext>
    private(set) var pops: DynamicContextTable<PopContext>

    let symbols: GameSaveSymbols
    let rules: GameRules
}
extension GameContext {
    static func load(_ save: borrowing GameSave, rules: GameRules) throws -> Self {
        let _none: _NoMetadata = .init()
        return .init(
            player: save.player,
            planets: [:],
            cultures: try .init(states: save.cultures) { _ in _none },
            countries: try .init(states: save.countries) { _ in _none },
            factories: try .init(states: save.factories) { rules.factories[$0.type] },
            mines: try .init(states: save.mines) { rules.mines[$0.type] },
            pops: try .init(states: save.pops) { rules.pops[$0.type] },
            symbols: save.symbols,
            rules: rules,
        )
    }

    func save(_ world: borrowing GameWorld) -> GameSave {
        .init(
            symbols: self.symbols,
            random: world.random,
            player: self.player,
            accounts: world.bank.accounts.items,
            tradeableMarkets: world.tradeableMarkets,
            inelasticMarkets: world.inelasticMarkets,
            date: world.date,
            cultures: [_].init(self.cultures.state),
            countries: [_].init(self.countries.state),
            factories: [_].init(self.factories.state),
            mines: [_].init(self.mines.state),
            pops: [_].init(self.pops.state),
            _factories: [],
            _pops: []
        )
    }
}
extension GameContext {
    mutating func seed(
        factories: [FactorySeed],
        pops: [PopSeed],
        symbols: GameSaveSymbols,
        world: inout GameWorld,
    ) throws {
        for seed: FactorySeed in factories {
            for factory: Quantity<FactoryType> in try seed.unpack(symbols: symbols) {
                let section: Factory.Section = .init(type: factory.unit, tile: seed.tile)
                try self.factories[section] {
                    rules.factories[$0.type]
                } update: {
                    $1.size = .init(level: 0, growthProgress: Factory.Size.growthRequired - 1)
                }
            }
        }
        // this is very slow, but we only do it once when initializing a new game
        for seed: PopSeed in pops {
            for pop: Pop in self.pops.state {
                if  let nat: String = seed.nat, pop.nat != nat {
                    continue
                }
                if  pop.type != seed.type {
                    continue
                }

                world.bank[account: .pop(pop.id)].s += seed.cash * pop.z.size
            }
        }
    }
}
extension GameContext {
    mutating func loadTerrain(from editor: PlanetTileEditor) throws {
        let terrain: TerrainType = try self.symbols[terrain: editor.terrain]
        let geology: GeologicalType = try self.symbols[geology: editor.geology]
        guard
        let terrain: TerrainMetadata = self.rules.terrains[terrain],
        let geology: GeologicalMetadata = self.rules.geology[geology] else {
            return
        }

        self.planets[editor.id] = .init(
            id: editor.id,
            name: editor.name,
            terrain: terrain,
            geology: geology
        )
        self.planets[editor.id.planet]?.grid.resurface(
            planet: editor.id.planet,
            rotate: editor.rotate,
            size: editor.size,
            terrainDefault: terrain,
            geologyDefault: geology
        )
    }

    mutating func loadTerrain(_ map: TerrainMap) throws {
        // Load planets
        let planetMetadata: PlanetContext.Metadata = .init()
        self.planets = try .init(states: map.planets) { _ in planetMetadata }
        // Initialize hex grids
        guard
        let terrainDefault: TerrainMetadata = self.rules.terrains.values.first else {
            fatalError("No terrain metadata found in rules!!!")
        }
        guard
        let geologyDefault: GeologicalMetadata = self.rules.geology.values.first else {
            fatalError("No geological metadata found in rules!!!")
        }
        let defined: [PlanetID: PlanetSurface] = map.planetSurfaces.reduce(into: [:]) {
            $0[$1.id] = $1
        }
        for i: Int in self.planets.indices {
            try {
                try $0.grid.replace(
                    surface: defined[$0.state.id] ?? .init(id: $0.state.id),
                    symbols: self.symbols,
                    rules: self.rules,
                    terrainDefault: terrainDefault,
                    geologyDefault: geologyDefault
                )
            } (&self.planets[i])
        }
    }

    func saveTerrain() -> TerrainMap {
        .init(
            planets: self.planets.map(\.state),
            planetSurfaces: self.planets.map {
                PlanetSurface.init(
                    id: $0.state.id,
                    size: $0.grid.size,
                    grid: $0.grid.tiles.values.map(PlanetSurface.Tile.init(from:))
                )
            }
        )
    }
}
extension GameContext {
    var pruningPass: PruningPass {
        .init(
            factories: self.factories.keys,
            mines: self.mines.keys,
            pops: self.pops.keys,
        )
    }

    var territoryPass: TerritoryPass {
        .init(
            player: self.player,
            planets: self.planets.state,
            cultures: self.cultures.state,
            countries: self.countries.state,
            factories: self.factories.state,
            mines: self.mines.state,
            pops: self.pops.state,
            rules: self.rules
        )
    }

    private var residentPass: ResidentPass {
        .init(
            player: self.player,
            planets: self.planets,
            cultures: self.cultures,
            countries: self.countries,
            factories: self.factories.state,
            mines: self.mines.state,
            pops: self.pops.state,
            rules: self.rules
        )
    }

    private var factoryPass: FactoryContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
            planets: self.planets,
        )
    }
    private var minePass: MineContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
            planets: self.planets,
        )
    }
    private var popPass: PopContext.ComputationPass {
        .init(
            player: self.player,
            rules: self.rules,
            planets: self.planets,
            factories: self.factories.state,
            mines: self.mines.state,
        )
    }
}
extension GameContext {
    private mutating func prune(world: inout GameWorld) {
        let retain: PruningPass = self.pruningPass

        world.bank.prune(in: retain)

        for i: Int in self.factories.indices {
            self.factories[i].state.prune(in: retain)
        }
        for i: Int in self.pops.indices {
            self.pops[i].state.prune(in: retain)
        }
    }
    private mutating func index(world: borrowing GameWorld) {
        for country: CountryContext in self.countries {
            for address: Address in country.state.controlledTiles {
                self.planets[address]?.update(
                    governedBy: country.properties,
                    occupiedBy: country.properties,
                )
            }
        }

        for i: Int in self.planets.indices {
            {
                for j: Int in $0.grid.tiles.values.indices {
                    $0.grid.tiles.values[j].startIndexCount()
                }
            } (&self.planets[i])
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
            /// avoid copy-on-write
            let (pop, stats): (Pop, Pop.Stats) = { ($0.state, $0.stats) } (self.pops[i])
            let counted: ()? = self.planets[pop.tile]?.addResidentCount(pop, stats)

            #assert(counted != nil, "Pop \(pop.id) has no home tile!!!")

            for job: FactoryJob in pop.factories.values {
                self.factories[modifying: job.id].addWorkforceCount(pop: pop, job: job)
            }
            for job: MiningJob in pop.mines.values {
                self.mines[modifying: job.id].addWorkforceCount(pop: pop, job: job)
            }
            /// We compute this here, and not in `PopContext.compute`, so that its global
            /// context can exclude the pop table itself, allowing us to mutate `PopContext`
            /// in-place there without individually retaining and releasing every `PopContext`
            /// in the array on every loop iteration, which would be O(n²)!
            let equity: Equity<LEI>.Statistics = .compute(
                equity: pop.equity,
                assets: world.bank[account: .pop(pop.id)],
                in: self.residentPass
            )
            self.pops[i].update(equityStatistics: equity)

            for stake: EquityStake<LEI> in pop.equity.shares.values {
                switch stake.id {
                case .pop(let id):
                    self.pops[modifying: id].addPosition(
                        asset: pop.id.lei,
                        value: stake.shares
                    )

                case .factory(let id):
                    self.factories[modifying: id].addPosition(
                        asset: pop.id.lei,
                        value: stake.shares
                    )
                }
            }
        }
        for i: Int in self.factories.indices {
            let factory: Factory = self.factories.state[i]
            let counted: ()? = self.planets[factory.tile]?.addResidentCount(factory)

            #assert(counted != nil, "Factory \(factory.id) has no home tile!!!")

            let equity: Equity<LEI>.Statistics = .compute(
                equity: factory.equity,
                assets: world.bank[account: .factory(factory.id)],
                in: self.residentPass
            )
            self.factories[i].update(equityStatistics: equity)

            for stake: EquityStake<LEI> in factory.equity.shares.values {
                // TODO: this isn’t correctly taking into account pop/factory death
                switch stake.id {
                case .pop(let id):
                    self.pops[modifying: id].addPosition(
                        asset: factory.id.lei,
                        value: stake.shares
                    )

                case .factory(let id):
                    self.factories[modifying: id].addPosition(
                        asset: factory.id.lei,
                        value: stake.shares
                    )
                }
            }
        }
        for i: Int in self.mines.indices {
            let mine: Mine = self.mines.state[i]
            let counted: ()? = self.planets[mine.tile]?.addResidentCount(mine)

            #assert(counted != nil, "Mine \(mine.id) has no home tile!!!")
        }
    }
}
extension GameContext {
    mutating func advance(_ turn: inout Turn) throws {
        turn.notifications.turn()
        turn.bank.turn()

        for i: Int in self.planets.indices {
            try self.planets[i].advance(turn: &turn, context: self)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].advance(turn: &turn, context: self)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].advance(turn: &turn, context: self)
        }

        // need to call this first, to update prices before trading
        turn.localMarkets.turn {
            guard
            let region: RegionalProperties = self.planets[$0.id.location]?.properties else {
                fatalError("LocalMarket \($0.id) exists in a tile with no authority!!!")
            }

            $0.turn(template: region.occupiedBy.localMarkets[$0.id.resource])
        }

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
        turn.stockMarkets.turn(random: &turn.random) {
            switch $2.asset {
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

        let shuffled: ResidentOrder = .randomize(
            (self.factories, Resident.factory(_:)),
            (self.pops, Resident.pop(_:)),
            with: &turn.random.generator
        )

        for i: Resident in shuffled.residents {
            switch i {
            case .factory(let i): self.factories[i].transact(turn: &turn)
            case .pop(let i): self.pops[i].transact(turn: &turn)
            }
        }

        turn.worldMarkets.turn()

        self.factories.turn { $0.advance(turn: &turn) }
        self.mines.turn { $0.advance(turn: &turn) }
        self.pops.turn { $0.advance(turn: &turn) }

        let unfilled: (
            [(PopType, [PopJobOfferBlock])],
            [(PopType, [PopJobOfferBlock])]
        ) = self.postPopHirings(&turn, order: shuffled)
        self.postPopFirings(&turn)

        self.awardRanksToFactories([unfilled.0, unfilled.1].joined())
        self.awardRanksToMines()

        try self.executeMovements(&turn)

        self.destroyObjects()
    }

    mutating func compute(_ world: inout GameWorld) throws {
        self.prune(world: &world)
        self.index(world: world)

        for i: Int in self.planets.indices {
            try self.planets[i].afterIndexCount(world: world, context: self.territoryPass)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].afterIndexCount(world: world, context: self.territoryPass)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].afterIndexCount(world: world, context: self.territoryPass)
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
    private mutating func report(resource: Resource, fill: LocalMarket.Fill, side: LocalMarket.Side) {
        switch fill.entity {
        case .factory(let id):
            self.factories[modifying: id].state.inventory.report(
                resource: resource,
                fill: fill,
                side: side
            )

        case .pop(let id):
            if  case .sell = side,
                case .mine(let mine)? = fill.memo {
                self.pops[modifying: id].state.mines[mine]?.out.inelastic[resource]?.report(
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
            let type: PopType = $0.state.type
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
        [(PopType, [PopJobOfferBlock])],
        [(PopType, [PopJobOfferBlock])]
    ) {
        let offers: (
            remote: [Turn.Jobs.Hire<PlanetID>.Key: [(Int, Int64)]],
            local: [Turn.Jobs.Hire<Address>.Key: [(Int, Int64)]]
        ) = order.residents.reduce(into: ([:], [:])) {
            guard case .pop(let i) = $1 else {
                return
            }

            let pop: Pop = self.pops.state[i]

            guard
            let jobMode: PopJobMode = pop.type.jobMode else {
                return
            }

            let unemployed: Int64 = pop.z.size - pop.employed()
            if  unemployed <= 0 {
                return
            }

            switch jobMode {
            case .hourly, .mining:
                let key: Turn.Jobs.Hire<Address>.Key = .init(
                    location: pop.tile,
                    type: pop.type
                )
                $0.local[key, default: []].append((i, unemployed))

            case .remote:
                let key: Turn.Jobs.Hire<PlanetID>.Key = .init(
                    location: pop.tile.planet,
                    type: pop.type
                )
                $0.remote[key, default: []].append((i, unemployed))
            }
        }

        let workersUnavailable: [(PopType, [PopJobOfferBlock])] = turn.jobs.hire.local.turn {
            if var pops: [(index: Int, unemployed: Int64)] = offers.local[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }
        let clerksUnavailable: [(PopType, [PopJobOfferBlock])] = turn.jobs.hire.remote.turn {
            if var pops: [(index: Int, unemployed: Int64)] = offers.remote[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }

        return (workersUnavailable, clerksUnavailable)
    }

    private mutating func postPopHirings(
        matching pops: inout [(index: Int, unemployed: Int64)],
        with offers: inout [PopJobOfferBlock]
    ) {
        /// We iterate through the pops for as many times as there are job offers. This
        /// means pops near the front of the list are more likely to be visited multiple
        /// times. However, since the pop index array is shuffled, this is fair over time.
        let candidates: Int = pops.count
        let iterations: Int = offers.count
        var iteration: Int = 0
        while let i: Int = offers.indices.last, iteration < iterations {
            let block: PopJobOfferBlock = offers[i]
            let match: (id: Int, (count: Int64, remaining: PopJobOfferBlock?))? = {
                $0.unemployed > 0 ? ($0.index, block.matched(with: &$0.unemployed)) : nil
            } (&pops[iteration % candidates])

            iteration += 1

            guard
            let (pop, (count, remaining)): (Int, (Int64, PopJobOfferBlock?)) = match else {
                // Pop has no more unemployed members.
                continue
            }

            if  let remaining: PopJobOfferBlock {
                offers[i] = remaining
            } else {
                offers.removeLast()
            }

            switch block.job {
            case .factory(let id):
                self.pops[pop].state.factories[id, default: .init(id: id)].hire(count)
            case .mine(let id):
                self.pops[pop].state.mines[id, default: .init(id: id)].hire(count)
            }
        }
    }
}
extension GameContext {
    private mutating func awardRanksToFactories(
        _ types: some Sequence<(PopType, [PopJobOfferBlock])>
    ) {
        for (type, unfilled): (PopType, [PopJobOfferBlock]) in types {
            /// The last `q` factories will always raise wages. The next factory after the first
            /// `q` will raise wages with probability `r / 8`.
            let (q, r): (Int, remainder: Int) = unfilled.count.quotientAndRemainder(
                dividingBy: FactoryContext.pr
            )
            for (position, block): (Int, PopJobOfferBlock) in unfilled.enumerated() {
                let probability: Int

                switch position {
                case 0 ..< q:
                    probability = FactoryContext.pr
                case q:
                    probability = r
                case _:
                    probability = 0
                }

                switch block.job {
                case .factory(let id):
                    {
                        if type.stratum <= .Worker {
                            $0.wf = probability
                        } else {
                            $0.cf = probability
                        }
                    } (&self.factories[modifying: id].state.z)

                case .mine:
                    break
                }
            }
        }
    }
    private mutating func awardRanksToMines() {
        for i: Int in self.planets.indices {
            for tile: PlanetGrid.Tile in self.planets[i].grid.tiles.values {
                var ranks: [PopType: [(id: MineID, yield: Double)]] = [:]
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
                    conversion.size %/ (conversion.size + $1.z.size)
                )

                $1.z.size += conversion.size
                $1.z.mil = weight.mix(inherited.mil, $1.z.mil)
                $1.z.con = weight.mix(inherited.con, $1.z.con)
                return $1.id
            }

            turn.bank[account: .pop(target)].d += inheritedCash
        }
    }
    private mutating func executeConstructions(_ turn: inout Turn) throws {
        for i: Int in self.planets.indices {
            for j: Int in self.planets[i].grid.tiles.values.indices {
                let (factory, mine, tile): (
                    FactoryMetadata?,
                    (type: MineMetadata, size: Int64)?,
                    Address
                ) = {
                    let factory: FactoryMetadata? = $0.pickFactory(
                        among: self.rules.factories,
                        using: &turn.random
                    )
                    let mine: (type: MineMetadata, size: Int64)? = $0.pickMine(
                        among: self.rules.mines,
                        turn: &turn
                    )
                    return (factory: factory, mine: mine, tile: $0.id)
                } (&self.planets[i][j])

                if  let type: FactoryMetadata = factory {
                    let factory: Factory.Section = .init(type: type.id, tile: tile)
                    try self.factories[factory] {
                        _ in type
                    } update: {
                        $1.size = .init(level: 0)
                    }
                }

                if  let (type, size): (MineMetadata, Int64) = mine {
                    let mine: Mine.Section = .init(type: type.id, tile: tile)
                    try self.mines[mine] {
                        _ in type
                    } update: {
                        $1.z.size += size
                        $1.last = Mine.Expansion.init(size: size, date: turn.date)
                    }
                }
            }
        }
    }
}
extension GameContext {
    private mutating func destroyObjects() {
        self.factories.lint()
        self.mines.lint()
        self.pops.lint()
    }
}
