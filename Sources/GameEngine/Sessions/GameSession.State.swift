import GameIDs
import GameRules
import GameTerrain

extension GameSession {
    struct State: ~Copyable {
        var context: GameContext
        var world: GameWorld

        init(context: GameContext, world: consuming GameWorld) {
            self.context = context
            self.world = world
        }
    }
}
extension GameSession.State {
    static func load(
        _ save: GameSave,
        rules: consuming GameMetadata,
        map: borrowing TerrainMap,
    ) throws -> Self {
        let world: GameWorld = .init(
            notifications: .init(date: save.date),
            bank: .init(accounts: save.accounts.dictionary),
            segmentedMarkets: save.segmentedMarkets,
            tradeableMarkets: save.tradeableMarkets,
            // placeholder
            tradeRoutes: [:],
            random: save.random,
        )

        var context: GameContext = try .load(save, rules: rules)
        try context.loadTerrain(map)

        return .init(context: context, world: world)
    }

    mutating func tick() throws {
        try self.context.advance(&self.world[self.context.rules.settings])
        try self.sync()
    }

    mutating func sync() throws {
        try self.context.compute(&self.world)
    }

    var save: GameSave {
        self.context.save(self.world)
    }
}

extension GameSession.State {
    var snapshot: GameSnapshot {
        .init(
            player: self.context.player,
            currencies: self.context.currencies,
            countries: self.context.countries,
            planets: self.context.planets,
            rules: self.context.rules,
            markets: (self.world.tradeableMarkets, self.world.segmentedMarkets),
            bank: self.world.bank,
            date: self.world.date
        )
    }
}
#if TESTABLE
extension GameSession.State {
    mutating func run(until date: GameDate) throws {
        try self.context.compute(&self.world)
        while self.world.date < date {
            try self.context.advance(&self.world[self.context.rules.settings])
            try self.context.compute(&self.world)

            if case (year: let year, month: 1, day: 1) = self.world.date.gregorian {
                print("Year \(year) has started.")
            }
        }
    }

    var _hash: Int {
        var hasher: Hasher = .init()
        self.context.pops.state.hash(into: &hasher)
        self.context.factories.state.hash(into: &hasher)
        return hasher.finalize()
    }

    static func != (a: borrowing Self, b: borrowing Self) -> Bool {
        a.context.pops.state != b.context.pops.state ||
        a.context.factories.state != b.context.factories.state
    }
}
#endif
