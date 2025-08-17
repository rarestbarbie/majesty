import Assert
import GameEconomy
import GameEngine
import GameRules
import JavaScriptKit

struct GameContext {
    var date: GameDate
    var player: GameID<Country>

    private(set) var planets: Table<PlanetContext>
    private(set) var cultures: Table<CultureContext>
    private(set) var countries: Table<CountryContext>
    private(set) var factories: Table<FactoryContext>
    private(set) var pops: Sectioned<PopContext>

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
        let defined: [GameID<Planet>: PlanetSurface] = surfaces.reduce(into: [:]) {
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
    var state: GameState {
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
            try self.planets[i].compute(in: self.state)
        }
        for i: Int in self.cultures.indices {
            try self.cultures[i].compute(in: self.state)
        }
        for i: Int in self.countries.indices {
            try self.countries[i].compute(in: self.state)
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
            for planet: GameID<Planet> in country.state.territory {
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
        for (pop, ct): (GameID<Pop>, CashTransfers) in map.transfers {
            self.pops.table[pop]?.state.cash += ct
        }
    }

    private mutating func postPopEmployment(_ map: inout GameMap, p: [Int]) {
        let pops: [GameMap.Jobs.Key: [(Int, Int64)]] = p.reduce(into: [:]) {
            let pop: Pop = self.pops.table.state[$1]
            let unemployed: Int64 = pop.unemployed
            if  unemployed > 0 {
                let key: GameMap.Jobs.Key = .init(on: pop.home.planet, type: pop.type)
                $0[key, default: []].append(($1, unemployed))
            }
        }

        let jobs: GameMap.Jobs = map.jobs.turn {
            guard var pops: [(index: Int, unemployed: Int64)] = pops[$0] else {
                // No unemployed pops for this job type.
                return
            }

            /// We iterate through the pops for as many times as there are job offers. This
            /// means pops near the front of the list are more likely to be visited multiple
            /// times. However, since the pop index array is shuffled, this is fair over time.
            let candidates: Int = pops.count
            let iterations: Int = $1.count
            var iteration: Int = 0
            while let i: Int = $1.indices.last, iteration < iterations {
                let block: FactoryJobOfferBlock = $1[i]
                let interview: (Int, (size: Int64, remaining: FactoryJobOfferBlock?))? = {
                    $0.unemployed > 0 ? ($0.index, block.matched(with: &$0.unemployed)) : nil
                } (&pops[iteration % candidates])

                iteration += 1

                let match: Int
                let count: Int64

                switch interview {
                case nil:
                    // Pop has no more unemployed members.
                    continue

                case (let pop, (let workers, nil))?:
                    $1.removeLast()
                    match = pop
                    count = workers

                case (let pop, (let workers, let remaining?))?:
                    $1[i] = remaining
                    match = pop
                    count = workers
                }

                self.pops.table[match].state.jobs[block.at, default: .init(at: block.at)].hire(
                    count
                )
            }
        }

        for (key, unfilled): (GameMap.Jobs.Key, [FactoryJobOfferBlock]) in jobs.blocks {
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

                if key.type.stratum <= .Worker {
                    self.factories[block.at]?.state.today.wf = probability
                } else {
                    self.factories[block.at]?.state.today.cf = probability
                }
            }
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
