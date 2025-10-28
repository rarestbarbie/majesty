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

    let symbols: GameRules.Symbols
    let rules: GameRules

    /// Initialize a fresh game context from the given game state.
    init(save: borrowing GameSave, rules: GameRules) throws {
        /// We do not use metadata for these types of objects:
        let country: CountryContext.Metadata = .init()
        let culture: CultureContext.Metadata = .init()
        let _none: _NoMetadata = .init()

        self.player = save.player
        self.planets = [:]
        self.cultures = try .init(states: save.cultures) { _ in culture }
        self.countries = try .init(states: save.countries) { _ in country }
        self.factories = try .init(states: save.factories) { rules.factories[$0.type] }
        self.mines = try .init(states: save.mines) { _ in _none }
        self.pops = try .init(states: save.pops) { rules.pops[$0.type] }

        self.symbols = save.symbols
        self.rules = rules
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
            pops: self.pops.state,
            rules: self.rules
        )
    }
}
extension GameContext {
    mutating func advance(_ map: inout GameMap) throws {
        map.notifications.turn()

        for i: Int in self.planets.indices {
            try self.planets[i].advance(map: &map, context: self)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].advance(map: &map, context: self)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].advance(map: &map, context: self)
        }

        map.localMarkets.turn {
            /// Apply local minimum wages
            guard
            let country: CountryProperties = self.planets[$0.location]?.governedBy,
            let resource: ResourceMetadata = self.rules.resources[$0.resource] else {
                return
            }

            if let hours: Int64 = resource.hours {
                let priceFloor: LocalPrice = .init(country.minwage %/ hours)
                $1.turn(priceFloor: priceFloor, type: .minimumWage)
            } else {
                $1.turn()
            }
        }

        self.factories.turn { $0.turn(on: &map) }
        self.pops.turn { $0.turn(on: &map) }

        map.localMarkets.turn {
            let price: LocalPrice = $1.today.price
            let (asks, bids): (
                asks: [LocalMarket.Order],
                bids: [LocalMarket.Order]
            ) = $1.match(using: &map.random)

            var spread: Int64 = 0

            for order: LocalMarket.Order in asks {
                switch order.by {
                case .factory(let id):
                    spread -= self.factories[modifying: id].state.inventory.credit(
                        inelastic: $0.resource,
                        units: order.filled,
                        price: price
                    )

                case .pop(let id):
                    spread -= self.pops[modifying: id].state.inventory.credit(
                        inelastic: $0.resource,
                        units: order.filled,
                        price: price
                    )
                }
            }
            for order: LocalMarket.Order in bids {
                switch order.by {
                case .factory(let id):
                    spread += self.factories[modifying: id].state.inventory.debit(
                        inelastic: $0.resource,
                        units: order.filled,
                        price: price,
                        tier: order.tier
                    )
                case .pop(let id):
                    spread += self.pops[modifying: id].state.inventory.debit(
                        inelastic: $0.resource,
                        units: order.filled,
                        price: price,
                        tier: order.tier
                    )
                }
            }

            // TODO: do something with spread
        }
        map.stockMarkets.turn(random: &map.random) {
            switch $2.asset {
            case .factory(let id):
                self.factories[modifying: id].state.equity.trade(
                    random: &$0,
                    bank: &map.bank,
                    fill: $2
                )
            case .pop(let id):
                self.pops[modifying: id].state.equity.trade(
                    random: &$0,
                    bank: &map.bank,
                    fill: $2
                )
            }
        }

        let shuffled: ResidentOrder = .randomize(
            (self.factories, Resident.factory(_:)),
            (self.pops, Resident.pop(_:)),
            with: &map.random.generator
        )

        for i: Resident in shuffled.residents {
            switch i {
            case .factory(let i): self.factories[i].transact(map: &map)
            case .pop(let i): self.pops[i].transact(map: &map)
            }
        }

        map.exchange.turn()

        self.factories.turn { $0.advance(map: &map) }
        self.mines.turn { $0.advance(map: &map) }
        self.pops.turn { $0.advance(map: &map) }

        self.postCashTransfers(&map)
        self.postPopEmployment(&map, order: shuffled)

        try self.executeMovements(&map)

        self.destroyObjects()
    }

    mutating func compute(_ map: borrowing GameMap) throws {
        let retain: PruningPass = self.pruningPass
        for i: Int in self.factories.indices {
            self.factories[i].state.prune(in: retain)
        }
        for i: Int in self.pops.indices {
            self.pops[i].state.prune(in: retain)
        }

        self.index()

        for i: Int in self.planets.indices {
            try self.planets[i].compute(map: map, context: self.territoryPass)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].compute(map: map, context: self.territoryPass)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].compute(map: map, context: self.territoryPass)
        }

        for i: Int in self.factories.indices {
            try self.factories[i].compute(map: map, context: self.residentPass)
        }
        for i: Int in self.mines.indices {
            try self.mines[i].compute(map: map, context: self.residentPass)
        }
        for i: Int in self.pops.indices {
            try self.pops[i].compute(map: map, context: self.residentPass)
        }
    }
}
extension GameContext {
    private mutating func index() {
        for country: CountryContext in self.countries {
            for planet: PlanetID in country.state.controlledWorlds {
                self.planets[planet]?.grid.assign(
                    governedBy: country.properties,
                    occupiedBy: country.properties
                )
            }
            for address: Address in country.state.controlledTiles {
                self.planets[address.planet]?.grid.assign(
                    governedBy: country.properties,
                    occupiedBy: country.properties,
                    to: address.tile
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
            let pop: Pop = self.pops.state[i]
            let counted: ()? = self.planets[pop.tile]?.addResidentCount(pop)

            #assert(counted != nil, "Pop \(pop.id) has no home tile!!!")

            for job: FactoryJob in pop.factories.values {
                self.factories[modifying: job.id].addWorkforceCount(pop: pop, job: job)
            }
            for job: MiningJob in pop.mines.values {
                self.mines[modifying: job.id].addWorkforceCount(pop: pop, job: job)
            }
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
    }
}
extension GameContext {
    private mutating func postCashTransfers(_ map: inout GameMap) {
        map.bank.turn {
            switch $0 {
            case .factory(let id):
                self.factories[modifying: id].state.inventory.account += $1
            case .pop(let id):
                self.pops[modifying: id].state.inventory.account += $1
            }
        }
    }

    private mutating func postPopEmployment(_ map: inout GameMap, order: ResidentOrder) {
        self.postPopHirings(&map, order: order)
        self.postPopFirings(&map)
    }

    private mutating func postPopFirings(_ map: inout GameMap) {
        var layoffs: [GameMap.Jobs.Fire.Key: PopJobLayoffBlock] = map.jobs.fire.turn()

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
    private mutating func postPopHirings(_ map: inout GameMap, order: ResidentOrder) {
        let offers: (
            remote: [GameMap.Jobs.Hire<PlanetID>.Key: [(Int, Int64)]],
            local: [GameMap.Jobs.Hire<Address>.Key: [(Int, Int64)]]
        ) = order.residents.reduce(into: ([:], [:])) {
            guard case .pop(let i) = $1 else {
                return
            }

            let pop: Pop = self.pops.state[i]

            guard
            let jobMode: PopJobMode = pop.type.jobMode else {
                return
            }

            let unemployed: Int64 = pop.unemployed
            if  unemployed <= 0 {
                return
            }

            switch jobMode {
            case .hourly, .mining:
                let key: GameMap.Jobs.Hire<Address>.Key = .init(
                    location: pop.tile,
                    type: pop.type
                )
                $0.local[key, default: []].append((i, unemployed))

            case .remote:
                let key: GameMap.Jobs.Hire<PlanetID>.Key = .init(
                    location: pop.tile.planet,
                    type: pop.type
                )
                $0.remote[key, default: []].append((i, unemployed))
            }
        }

        let workersUnavailable: [
            (PopType, [PopJobOfferBlock])
        ] = map.jobs.hire.local.turn {
            if var pops: [(index: Int, unemployed: Int64)] = offers.local[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }
        let clerksUnavailable: [
            (PopType, [PopJobOfferBlock])
        ] = map.jobs.hire.remote.turn {
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
                    } (&self.factories[modifying: id].state.today)

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
    private mutating func executeMovements(_ map: inout GameMap) throws {
        try self.executeConversions(&map)
        try self.executeConstructions(&map)
    }
    private mutating func executeConversions(_ map: inout GameMap) throws {
        defer {
            map.conversions.removeAll(keepingCapacity: true)
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

        for conversion: Pop.Conversion in map.conversions {
            let inherited: (cash: Int64, mil: Double, con: Double) = {
                (
                    $0.state.inventory.account.inherit(fraction: conversion.inherits),
                    $0.state.today.mil,
                    $0.state.today.con
                )
            } (&self.pops[modifying: conversion.from])

            // TODO: pops should also inherit stock portfolios and slaves

            try self.pops[conversion.to] {
                self.rules.pops[$0.type]
            } update: {
                let weight: Fraction.Interpolator<Double> = .init(
                    conversion.size %/ (conversion.size + $0.today.size)
                )

                $0.today.size += conversion.size
                $0.inventory.account.d += inherited.cash
                $0.today.mil = weight.mix(inherited.mil, $0.today.mil)
                $0.today.con = weight.mix(inherited.con, $0.today.con)
            }
        }
    }
    private mutating func executeConstructions(_ map: inout GameMap) throws {
        for i: Int in self.planets.indices {
            for j: Int in self.planets[i].grid.tiles.values.indices {
                let factory: Factory.Section? = {
                    let id: PlanetID = $0.state.id
                    return {
                        guard
                        let selected: FactoryType = $0.pickFactory(
                            among: self.rules.factories,
                            using: &map.random
                        )  else {
                            return nil
                        }
                        return .init(type: selected, tile: .init(planet: id, tile: $0.id))

                    } (&$0[j])
                } (&self.planets[i])

                guard
                let factory: Factory.Section else {
                    continue
                }

                try self.factories[factory] {
                    self.rules.factories[$0.type]
                } update: {
                    $0.size = .init(level: 0)
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
