import Assert
import GameEconomy
import GameRules
import GameState
import JavaScriptKit

struct GameContext {
    var date: GameDate
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
        let planet: PlanetContext.Metadata = .init()
        let country: CountryContext.Metadata = .init()
        let culture: CultureContext.Metadata = .init()

        self.date = save.date
        self.player = save.player
        self.planets = try .init(states: save.planets) { _ in planet }
        self.cultures = try .init(states: save.cultures) { _ in culture }
        self.countries = try .init(states: save.countries) { _ in country }
        self.factories = try .init(states: save.factories) { rules.factories[$0.type] }
        self.pops = try .init(states: save.pops) { rules.pops[$0.type] }

        self.symbols = save.symbols
        self.rules = rules
    }
}
extension GameContext {
    mutating func loadTerrain(from editor: PlanetTileEditor) {
        guard let terrain: TerrainMetadata = self.rules.terrains[editor.type] else {
            return
        }

        self.planets[editor.on]?.cells[editor.id]?.self = .init(
            id: editor.id,
            type: terrain,
            tile: editor.tile
        )
        self.planets[editor.on]?.resurface(
            rotate: editor.rotate,
            size: editor.size,
            terrainDefault: terrain
        )
    }

    mutating func loadTerrain(_ surfaces: [PlanetSurface]) throws {
        // Initialize hex grids
        guard
        let terrainDefault: TerrainMetadata = self.rules.terrains.values.first else {
            fatalError("No terrain metadata found in rules!!!")
        }
        let defined: [PlanetID: PlanetSurface] = surfaces.reduce(into: [:]) {
            $0[$1.id] = $1
        }
        for i: Int in self.planets.indices {
            try {
                try $0.replace(
                    surface: defined[$0.state.id],
                    symbols: self.symbols,
                    rules: self.rules,
                    terrainDefault: terrainDefault,
                )
            } (&self.planets[i])
        }
    }

    func saveTerrain() -> [PlanetSurface] {
        self.planets.map {
            PlanetSurface.init(
                id: $0.state.id,
                size: $0.size,
                grid: $0.cells.values.map {
                    .init(id: $0.id, type: $0.type.name, tile: $0.tile)
                }
            )
        }
    }
}
extension GameContext {
    var territoryPass: TerritoryPass {
        .init(
            date: self.date,
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
            date: self.date,
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
        self.date.increment()

        for i: Int in self.planets.indices {
            try self.planets[i].advance(in: self, on: &map)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].advance(in: self, on: &map)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].advance(in: self, on: &map)
        }

        self.settleCashTransfers()

        self.factories.turnAll()
        self.pops.table.turnAll()

        var order: [Resident] = []

        order.reserveCapacity(self.factories.count + self.pops.table.count)
        order += self.factories.indices.lazy.map(Resident.factory(_:))
        order += self.pops.table.indices.lazy.map(Resident.pop(_:))
        order.shuffle(using: &map.random.generator)

        for i: Resident in order {
            switch i {
            case .factory(let i):
                try self.factories[i].advance(in: self, on: &map)
            case .pop(let i):
                try self.pops.table[i].advance(in: self, on: &map)
            }
        }

        self.postCashTransfers(&map)
        self.postPopEmployment(&map, p: order.compactMap(\.pop))
        try self.postPopConversions(&map)

        map.exchange.turn(history: 365)
    }

    mutating func compute() throws {
        for i: Int in self.planets.indices {
            try self.planets[i].compute(in: self.territoryPass)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].compute(in: self.territoryPass)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].compute(in: self.territoryPass)
        }

        self.index()

        for i: Int in self.factories.indices {
            try self.factories[i].compute(in: self.residentPass)
        }
        for i: Int in self.pops.table.indices {
            try self.pops.table[i].compute(in: self.residentPass)
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
                for j: Int in $0.cells.values.indices {
                    $0.cells.values[j].startIndexCount()
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
            let counted: ()? = self.planets[home.planet]?.cells[home.tile]?.addResidentCount(
                pop: pop.state
            )

            #assert(counted != nil, "Pop \(pop.state.id) has no home tile!!!")

            for job: FactoryJob in pop.state.jobs.values {
                self.factories[job.at]?.addWorkforceCount(pop: pop.state, job: job)
            }
            // TODO: handle missing factories/slaves
            for stocks: Property<Factory> in pop.state.stocks.values {
                self.factories[stocks.id]?.addShareholderCount(
                    pop: pop.state,
                    shares: stocks.shares,
                )
            }
            for slaves: Property<Pop> in pop.state.slaves.values {
                self.pops.table[slaves.id]?.addShareholderCount(
                    pop: pop.state,
                    shares: slaves.shares
                )
            }
        }
    }
}
extension GameContext {
    private mutating func settleCashTransfers() {
        for i: Int in self.factories.indices {
            self.factories[i].state.cash.settle()
        }
        for i: Int in self.pops.table.indices {
            self.pops.table[i].state.cash.settle()
        }
    }

    private mutating func postCashTransfers(_ map: inout GameMap) {
        defer {
            map.transfers.removeAll(keepingCapacity: true)
        }
        for (pop, ct): (PopID, CashTransfers) in map.transfers {
            self.pops.table[pop]?.state.cash += ct
        }
    }

    private mutating func postPopEmployment(_ map: inout GameMap, p: [Int]) {
        let (workers, clerks): (
            [GameMap.Jobs<Address>.Key: [(Int, Int64)]],
            [GameMap.Jobs<PlanetID>.Key: [(Int, Int64)]]
        ) = p.reduce(into: (worker: [:], clerk: [:])) {
            let pop: Pop = self.pops.table.state[$1]
            let unemployed: Int64 = pop.unemployed
            if  unemployed <= 0 {
                return
            }
            if  pop.type.stratum <= .Worker {
                let key: GameMap.Jobs<Address>.Key = .init(
                    location: pop.home,
                    type: pop.type
                )
                $0.worker[key, default: []].append(($1, unemployed))
            } else {
                let key: GameMap.Jobs<PlanetID>.Key = .init(
                    location: pop.home.planet,
                    type: pop.type
                )
                $0.clerk[key, default: []].append(($1, unemployed))
            }
        }

        let workersUnavailable: [(PopType, [FactoryJobOfferBlock])] = map.jobs.worker.turn {
            if var pops: [(index: Int, unemployed: Int64)] = workers[$0] {
                self.postPopEmployment(matching: &pops, with: &$1)
            }
        }
        let clerksUnavailable: [(PopType, [FactoryJobOfferBlock])] = map.jobs.clerk.turn {
            if var pops: [(index: Int, unemployed: Int64)] = clerks[$0] {
                self.postPopEmployment(matching: &pops, with: &$1)
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

    private mutating func postPopEmployment(
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
