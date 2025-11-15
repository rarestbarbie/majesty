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
        var factories: DynamicContextTable<FactoryContext> = try .init(states: save.factories) {
            rules.factories[$0.type]
        }
        for seed: FactorySeed in save._factories {
            for factory: Quantity<FactoryType> in try seed.unpack(symbols: save.symbols) {
                let section: Factory.Section = .init(type: factory.unit, tile: seed.tile)
                try factories[section] {
                    rules.factories[$0.type]
                } update: {
                    $1.size = .init(level: 0, growthProgress: Factory.Size.growthRequired - 1)
                }
            }
        }
        return .init(
            player: save.player,
            planets: [:],
            cultures: try .init(states: save.cultures) { _ in _none },
            countries: try .init(states: save.countries) { _ in _none },
            factories: factories,
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
            tradeableMarkets: world.tradeableMarkets,
            inelasticMarkets: world.inelasticMarkets,
            date: world.date,
            cultures: [_].init(self.cultures.state),
            countries: [_].init(self.countries.state),
            factories: [_].init(self.factories.state),
            mines: [_].init(self.mines.state),
            pops: [_].init(self.pops.state),
            _factories: [],
        )
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

        self.planets[editor.on]?.grid.tiles[editor.id]?.self = .init(
            id: editor.id,
            name: editor.name,
            terrain: terrain,
            geology: geology
        )
        self.planets[editor.on]?.grid.resurface(
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
                    surface: defined[$0.state.id],
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
    private mutating func prune() {
        let retain: PruningPass = self.pruningPass
        for i: Int in self.factories.indices {
            self.factories[i].state.prune(in: retain)
        }
        for i: Int in self.pops.indices {
            self.pops[i].state.prune(in: retain)
        }
    }
    private mutating func index() {
        for country: CountryContext in self.countries {
            for planet: PlanetID in country.state.controlledWorlds {
                self.planets[planet]?.grid.assign(
                    governedBy: country.properties,
                    occupiedBy: country.properties
                )
            }
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
                assets: pop.inventory.account,
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
                assets: factory.inventory.account,
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

        for i: Int in self.planets.indices {
            try self.planets[i].advance(turn: &turn, context: self)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].advance(turn: &turn, context: self)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].advance(turn: &turn, context: self)
        }

        turn.localMarkets.turn {
            /// Apply local minimum wages
            guard
            let region: RegionalProperties = self.planets[$0.id.location]?.properties,
            let resource: ResourceMetadata = self.rules.resources[$0.id.resource] else {
                return
            }

            let min: LocalPriceLevel?

            if let hours: Int64 = resource.hours {
                min = .init(
                    price: LocalPrice.init(region.minwage %/ hours),
                    label: .minimumWage
                )
            } else {
                min = nil
            }

            $0.turn(priceControls: (min: min, max: nil))
        }

        self.factories.turn { $0.turn(on: &turn) }
        self.mines.turn { $0.turn(on: &turn) }
        self.pops.turn { $0.turn(on: &turn) }

        turn.localMarkets.turn {
            let price: LocalPrice = $0.today.price
            let (asks, bids): (
                asks: [LocalMarket.Order],
                bids: [LocalMarket.Order]
            ) = $0.match(using: &turn.random)

            var spread: Int64 = 0

            for order: LocalMarket.Order in asks {
                switch order.by {
                case .factory(let id):
                    let (credited, _): (Int64, reported: Bool) = self.factories[modifying: id].state.inventory.credit(
                        inelastic: $0.id.resource,
                        units: order.filled,
                        price: price
                    )
                    spread -= credited

                case .pop(let id):
                    let (credited, _): (Int64, reported: Bool) = self.pops[modifying: id].state.inventory.credit(
                        inelastic: $0.id.resource,
                        units: order.filled,
                        price: price
                    )

                    spread -= credited

                    if let memo: MineID = order.memo {
                        // Log unreported mining output
                        self.pops[modifying: id].state.mines[memo]?.out.inelastic[$0.id.resource]?.report(
                            unitsSold: order.filled,
                            valueSold: credited,
                        )
                    }
                }
            }
            for order: LocalMarket.Order in bids {
                #assert(order.filled <= order.amount, "Order overfilled! (\(order))")

                switch order.by {
                case .factory(let id):
                    spread += self.factories[modifying: id].state.inventory.debit(
                        inelastic: $0.id.resource,
                        units: order.filled,
                        price: price,
                        tier: order.tier
                    )
                case .pop(let id):
                    spread += self.pops[modifying: id].state.inventory.debit(
                        inelastic: $0.id.resource,
                        units: order.filled,
                        price: price,
                        tier: order.tier
                    )
                }
            }

            // TODO: do something with spread
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

        self.postCashTransfers(&turn)
        self.postPopEmployment(&turn, order: shuffled)

        try self.executeMovements(&turn)

        self.destroyObjects()
    }

    mutating func compute(_ world: borrowing GameWorld) throws {
        self.prune()
        self.index()

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
    private mutating func postCashTransfers(_ turn: inout Turn) {
        turn.bank.turn {
            switch $0 {
            case .factory(let id):
                self.factories[modifying: id].state.inventory.account += $1
            case .pop(let id):
                self.pops[modifying: id].state.inventory.account += $1
            }
        }
    }

    private mutating func postPopEmployment(_ turn: inout Turn, order: ResidentOrder) {
        self.postPopHirings(&turn, order: order)
        self.postPopFirings(&turn)
    }

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
    private mutating func postPopHirings(_ turn: inout Turn, order: ResidentOrder) {
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

        let workersUnavailable: [
            (PopType, [PopJobOfferBlock])
        ] = turn.jobs.hire.local.turn {
            if var pops: [(index: Int, unemployed: Int64)] = offers.local[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }
        let clerksUnavailable: [
            (PopType, [PopJobOfferBlock])
        ] = turn.jobs.hire.remote.turn {
            if var pops: [(index: Int, unemployed: Int64)] = offers.remote[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }

        for (type, unfilled): (PopType, [PopJobOfferBlock])
            in [clerksUnavailable, workersUnavailable].joined() {
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
            let inherited: (cash: Int64, mil: Double, con: Double) = {
                (
                    $0.state.inventory.account.inherit(fraction: conversion.inherits),
                    $0.state.z.mil,
                    $0.state.z.con
                )
            } (&self.pops[modifying: conversion.from])

            // TODO: pops should also inherit stock portfolios and slaves

            try self.pops[conversion.to] {
                self.rules.pops[$0.type]
            } update: {
                let weight: Fraction.Interpolator<Double> = .init(
                    conversion.size %/ (conversion.size + $1.z.size)
                )

                $1.z.size += conversion.size
                $1.inventory.account.d += inherited.cash
                $1.z.mil = weight.mix(inherited.mil, $1.z.mil)
                $1.z.con = weight.mix(inherited.con, $1.z.con)
            }
        }
    }
    private mutating func executeConstructions(_ turn: inout Turn) throws {
        for i: Int in self.planets.indices {
            for j: Int in self.planets[i].grid.tiles.values.indices {
                let (factory, mines, tile): (
                    FactoryType?,
                    [(type: MineType, size: Int64)],
                    Address
                ) = {
                    let id: PlanetID = $0.state.id
                    return {
                        let factory: FactoryType? = $0.pickFactory(
                            among: self.rules.factories,
                            using: &turn.random
                        )
                        let mines: [(type: MineType, size: Int64)] = $0.pickMine(
                            among: self.rules.mines,
                            using: &turn.random
                        )
                        let tile: Address = .init(planet: id, tile: $0.id)
                        return (factory: factory, mines: mines, tile: tile)
                    } (&$0[j])
                } (&self.planets[i])

                if  let factory: FactoryType {
                    let factory: Factory.Section = .init(type: factory, tile: tile)
                    try self.factories[factory] {
                        self.rules.factories[$0.type]
                    } update: {
                        $1.size = .init(level: 0)
                    }
                }

                for (mine, size): (MineType, Int64) in mines {
                    let mine: Mine.Section = .init(type: mine, tile: tile)
                    try self.mines[mine] {
                        self.rules.mines[$0.type]
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
