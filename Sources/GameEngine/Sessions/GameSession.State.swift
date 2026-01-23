import GameIDs
import GameRules
import GameTerrain

extension GameSession {
    @_spi(testable) public struct State: ~Copyable {
        var context: GameContext
        var world: GameWorld

        init(context: GameContext, world: consuming GameWorld) {
            self.context = context
            self.world = world
        }
    }
}
extension GameSession.State {
    @_spi(testable) public static func load(
        _ save: consuming GameSave,
        rules: borrowing GameRules
    ) throws -> Self {
        let metadata: GameMetadata = try rules.resolve(symbols: &save.symbols)
        return try .load(save, rules: metadata)
    }

    @_spi(testable) public static func load(
        start: consuming GameStart,
        rules: borrowing GameRules,
        map: borrowing TerrainMap
    ) throws -> Self {
        var metadata: GameMetadata = try rules.resolve(symbols: &start.symbols)
        let save: GameSave = try start.unpack(rules: &metadata, terrain: map)
        return try .load(save, rules: metadata)
    }

    private static func load(
        _ save: consuming GameSave,
        rules: consuming GameMetadata,
    ) throws -> Self {
        let world: GameWorld = .init(
            notifications: .init(date: save.date),
            bank: .init(accounts: save.accounts.dictionary),
            localMarkets: rules.settings.localMarkets.load(save.localMarkets),
            worldMarkets: rules.settings.worldMarkets.load(save.worldMarkets),
            // placeholder
            tradeRoutes: [:],
            // placeholder
            ledger: .init(),
            random: save.random,
        )

        return .init(context: try .load(save, rules: rules), world: world)
    }
}
extension GameSession.State {
    mutating func tick() throws {
        try self.context.advance(&self.world[self.context.rules.settings])
        try self.sync()
    }

    mutating func sync() throws {
        try self.context.compute(&self.world)
    }

    @_spi(testable) public var save: GameSave {
        self.context.save(self.world)
    }
}

#if TESTABLE
extension GameSession.State {
    @_spi(testable) public mutating func run(until date: GameDate) throws {
        try self.context.compute(&self.world)
        while self.world.date < date {
            try self.context.advance(&self.world[self.context.rules.settings])
            try self.context.compute(&self.world)

            if case (year: let year, month: 1, day: 1) = self.world.date.gregorian {
                print("Year \(year) has started.")
            }
        }
    }

    @_spi(testable) public var rules: GameMetadata {
        self.context.rules
    }

    @_spi(testable) public static func != (a: borrowing Self, b: borrowing Self) -> Bool {
        a.context.buildings.state != b.context.buildings.state ||
        a.context.factories.state != b.context.factories.state ||
        a.context.pops.state != b.context.pops.state ||
        a.context.mines.state != b.context.mines.state
    }
}
#endif
