import Assert
import GameEconomy
import GameRules
import GameState
import GameTerrain
import JavaScriptKit

struct GameContext {
    var player: CountryID

    private(set) var planets: RuntimeContextTable<PlanetContext>
    private(set) var cultures: RuntimeContextTable<CultureContext>
    private(set) var countries: RuntimeContextTable<CountryContext>
    private(set) var factories: RuntimeContextTable<FactoryContext>
    private(set) var pops: SectionedContextTable<PopContext>

    let symbols: GameRules.Symbols
    let rules: GameRules

    /// Initialize a fresh game context from the given game state.
    init(save: borrowing GameSave, rules: GameRules) throws {
        /// We do not use metadata for these types of objects:
        let country: CountryContext.Metadata = .init()
        let culture: CultureContext.Metadata = .init()

        self.player = save.player
        self.planets = [:]
        self.cultures = try .init(states: save.cultures) { _ in culture }
        self.countries = try .init(states: save.countries) { _ in country }
        self.factories = try .init(states: save.factories) { rules.factories[$0.type] }
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
    var territoryPass: TerritoryPass {
        .init(
            player: self.player,
            planets: self.planets.state,
            cultures: self.cultures.state,
            countries: self.countries.state,
            factories: self.factories.state,
            pops: self.pops.table.state,
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
            pops: self.pops.table.state,
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
            let country: CountryID = self.planets[$0.location.planet]?.occupied,
            let country: Country = self.countries.state[country] else {
                return
            }

            $1.turn(minwage: country.minwage)
        }

        self.factories.turn  { $0.turn(on: &map) }
        self.pops.table.turn { $0.turn(on: &map) }

        map.localMarkets.turn {
            let price: Int64 = $1.today.price
            let (asks, bids): (
                asks: [LocalMarket<PopID>.Order],
                bids: [LocalMarket<PopID>.Order]
            ) = $1.match(using: &map.random)

            for order: LocalMarket<PopID>.Order in asks {
                self.pops.table[order.by]?.credit(
                    inelastic: $0.resource,
                    units: order.filled,
                    price: price
                )
            }
            for order: LocalMarket<PopID>.Order in bids {
                self.pops.table[order.by]?.debit(
                    inelastic: $0.resource,
                    units: order.filled,
                    price: price,
                    in: order.tier
                )
            }
        }
        map.stockMarkets.turn {
            for fill: StockMarket<LegalEntity>.Fill in $1.match(using: &map.random) {
                switch fill.buyer {
                case .pop(let id):
                    self.pops.table[id]?.state.cash.e -= fill.cost
                case .factory(let id):
                    self.factories[id]?.state.cash.e -= fill.cost
                }
                switch fill.asset {
                case .pop(let id):
                    self.pops.table[id]?.state.issue(shares: fill)
                case .factory(let id):
                    self.factories[id]?.state.issue(shares: fill)
                }
            }
        }

        var order: [Resident] = []

        order.reserveCapacity(self.factories.count + self.pops.table.count)
        order += self.factories.indices.lazy.map(Resident.factory(_:))
        order += self.pops.table.indices.lazy.map(Resident.pop(_:))
        order.shuffle(using: &map.random.generator)

        for i: Resident in order {
            switch i {
            case .factory(let i):
                self.factories[i].transact(map: &map)
            case .pop(let i):
                self.pops.table[i].transact(map: &map)
            }
        }

        map.exchange.turn()

        self.factories.turn {
            $0.advance(map: &map)
        }
        self.pops.table.turn {
            $0.advance(map: &map, factories: self.factories.state)
        }

        self.postCashTransfers(&map)
        self.postPopEmployment(&map, p: order.compactMap(\.pop))

        try self.postPopConversions(&map)
    }

    mutating func compute(_ map: borrowing GameMap) throws {
        for i: Int in self.planets.indices {
            try self.planets[i].compute(map: map, context: self.territoryPass)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].compute(map: map, context: self.territoryPass)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].compute(map: map, context: self.territoryPass)
        }

        self.index()

        for i: Int in self.factories.indices {
            try self.factories[i].compute(map: map, context: self.residentPass)
        }
        for i: Int in self.pops.table.indices {
            try self.pops.table[i].compute(map: map, context: self.residentPass)
        }
    }
}
extension GameContext {
    private mutating func index() {
        for country: CountryContext in self.countries {
            for planet: PlanetID in country.state.territory {
                self.planets[planet]?.occupied = country.state.id
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
        for i: Int in self.pops.table.indices {
            self.pops.table[i].startIndexCount()
        }
        for pop: PopContext in self.pops.table {
            let home: Address = pop.state.home
            let counted: ()? = self.planets[home.planet]?.grid.tiles[home.tile]?.addResidentCount(
                pop: pop.state
            )

            #assert(counted != nil, "Pop \(pop.state.id) has no home tile!!!")

            let indenture: LegalEntity = .pop(pop.state.id)

            for job: FactoryJob in pop.state.jobs.values {
                self.factories[job.at]?.addWorkforceCount(pop: pop.state, job: job)
            }
            for stake: EquityStake<LegalEntity> in pop.state.equity.shares.values {
                let counted: ()?
                switch stake.id {
                case .pop(let id):
                    counted = self.pops.table[id]?.addPosition(
                        asset: indenture,
                        value: stake.shares
                    )

                case .factory(let id):
                    counted = self.factories[id]?.addPosition(
                        asset: indenture,
                        value: stake.shares
                    )
                }

                #assert(counted != nil, "Slaveowner \(stake.id) does not exist!!!")
            }
        }
        for factory: FactoryContext in self.factories {
            let title: LegalEntity = .factory(factory.state.id)
            for stake: EquityStake<LegalEntity> in factory.state.equity.shares.values {
                let counted: ()?
                switch stake.id {
                case .pop(let id):
                    counted = self.pops.table[id]?.addPosition(
                        asset: title,
                        value: stake.shares
                    )

                case .factory(let id):
                    counted = self.factories[id]?.addPosition(
                        asset: title,
                        value: stake.shares
                    )
                }

                #assert(counted != nil, "Shareholder \(stake.id) does not exist!!!")
            }
        }
    }
}
extension GameContext {
    private mutating func postCashTransfers(_ map: inout GameMap) {
        defer {
            map.transfers.removeAll(keepingCapacity: true)
        }
        for (recipient, transfers): (LegalEntity, CashTransfers) in map.transfers {
            switch recipient {
            case .pop(let id):
                self.pops.table[id]?.state.cash += transfers
            case .factory(let id):
                self.factories[id]?.state.cash += transfers
            }
        }
    }

    private mutating func postPopEmployment(_ map: inout GameMap, p: [Int]) {
        self.postPopHirings(&map, p: p)
        self.postPopFirings(&map, p: p)
    }

    private mutating func postPopFirings(_ map: inout GameMap, p: [Int]) {
        var layoffs: (
            workers: [FactoryID: FactoryJobLayoffBlock],
            clerks: [FactoryID: FactoryJobLayoffBlock]
        ) = (
            map.jobs.fire.worker.turn(),
            map.jobs.fire.clerk.turn()
        )

        for p: Int in p {
            {
                let stratum: PopStratum = $0.state.type.stratum
                for j: Int in $0.state.jobs.values.indices {
                    {
                        if stratum <= .Worker {
                            $0.fire(&layoffs.workers[$0.at])
                        } else {
                            $0.fire(&layoffs.clerks[$0.at])
                        }
                    } (&$0.state.jobs.values[j])
                }
            } (&self.pops.table[p])
        }
    }
    private mutating func postPopHirings(_ map: inout GameMap, p: [Int]) {
        let (workers, clerks): (
            [GameMap.Jobs.Hire<Address>.Key: [(Int, Int64)]],
            [GameMap.Jobs.Hire<PlanetID>.Key: [(Int, Int64)]]
        ) = p.reduce(into: (worker: [:], clerk: [:])) {
            let pop: Pop = self.pops.table.state[$1]
            let unemployed: Int64 = pop.unemployed
            if  unemployed <= 0 {
                return
            }
            if  pop.type.stratum <= .Worker {
                let key: GameMap.Jobs.Hire<Address>.Key = .init(
                    location: pop.home,
                    type: pop.type
                )
                $0.worker[key, default: []].append(($1, unemployed))
            } else {
                let key: GameMap.Jobs.Hire<PlanetID>.Key = .init(
                    location: pop.home.planet,
                    type: pop.type
                )
                $0.clerk[key, default: []].append(($1, unemployed))
            }
        }

        let workersUnavailable: [(PopType, [FactoryJobOfferBlock])] = map.jobs.hire.worker.turn {
            if var pops: [(index: Int, unemployed: Int64)] = workers[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }
        let clerksUnavailable: [(PopType, [FactoryJobOfferBlock])] = map.jobs.hire.clerk.turn {
            if var pops: [(index: Int, unemployed: Int64)] = clerks[$0] {
                self.postPopHirings(matching: &pops, with: &$1)
            }
        }

        for (type, unfilled): (PopType, [FactoryJobOfferBlock])
            in [clerksUnavailable, workersUnavailable].joined() {
            /// The last `q` factories will always raise wages. The next factory after the first
            /// `q` will raise wages with probability `r / 8`.
            let (q, r): (Int, remainder: Int) = unfilled.count.quotientAndRemainder(
                dividingBy: FactoryContext.pr
            )
            for (position, block): (Int, FactoryJobOfferBlock) in unfilled.enumerated() {
                let probability: Int

                switch position {
                case 0 ..< q:
                    probability = FactoryContext.pr
                case q:
                    probability = r
                case _:
                    probability = 0
                }

                if type.stratum <= .Worker {
                    self.factories[block.at]?.state.today.wf = probability
                } else {
                    self.factories[block.at]?.state.today.cf = probability
                }
            }
        }
    }

    private mutating func postPopHirings(
        matching pops: inout [(index: Int, unemployed: Int64)],
        with offers: inout [FactoryJobOfferBlock]
    ) {
        /// We iterate through the pops for as many times as there are job offers. This
        /// means pops near the front of the list are more likely to be visited multiple
        /// times. However, since the pop index array is shuffled, this is fair over time.
        let candidates: Int = pops.count
        let iterations: Int = offers.count
        var iteration: Int = 0
        while let i: Int = offers.indices.last, iteration < iterations {
            let block: FactoryJobOfferBlock = offers[i]
            let match: (id: Int, (count: Int64, remaining: FactoryJobOfferBlock?))? = {
                $0.unemployed > 0 ? ($0.index, block.matched(with: &$0.unemployed)) : nil
            } (&pops[iteration % candidates])

            iteration += 1

            guard
            let (pop, (count, remaining)): (Int, (Int64, FactoryJobOfferBlock?)) = match else {
                // Pop has no more unemployed members.
                continue
            }

            if  let remaining: FactoryJobOfferBlock {
                offers[i] = remaining
            } else {
                offers.removeLast()
            }

            self.pops.table[pop].state.jobs[block.at, default: .init(at: block.at)].hire(
                count
            )
        }
    }

    private mutating func postPopConversions(_ map: inout GameMap) throws {
        defer {
            map.conversions.removeAll(keepingCapacity: true)
        }
        for (count, target): (Int64, Pop.Section) in map.conversions {
            try self.pops.with(section: target) {
                self.rules.pops[$0.type]
            } update: {
                $0.today.size += count
            }
        }
    }
}
