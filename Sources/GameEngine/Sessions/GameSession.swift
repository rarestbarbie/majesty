import GameClock
import GameIDs
import GameRules
import GameTerrain
import GameUI
import JavaScriptInterop
import JavaScriptKit

public actor GameSession {
    private var clock: GameClock
    private var state: State

    nonisolated public let model: GameUI.Model

    private init(
        state: consuming State,
        clock: consuming GameClock = .init(),
        ui: consuming GameUI = .init()
    ) {
        self.clock = clock
        self.state = state
        self.model = .init(ui: ui)
    }
}
extension GameSession {
    private func publish() throws {
        let context: GameUI.CacheContext = .init(
            currencies: self.state.context.currencies,
            countries: self.state.context.countries.state.reduce(into: [:]) { $0[$1.id] = $1 },
            localMarkets: self.state.world.localMarkets,
            worldMarkets: self.state.world.worldMarkets,
            planets: self.state.context.planets.reduce(into: [:]) {
                $0[$1.state.id] = $1.snapshot
            },
            tiles: self.state.context.planets.reduce(into: [:]) {
                for tile: PlanetGrid.Tile in $1.grid.tiles.values {
                    $0[tile.id] = tile.snapshot
                }
            },
            bank: self.state.world.bank,
            date: self.state.world.date,
            player: self.state.context.player,
            speed: self.clock.speed,
            rules: self.state.context.rules
        )

        let bloc: CountryID = context.playerCountry.suzerain ?? context.player

        let cache: GameUI.Cache = .init(
            context: context,
            pops: self.state.context.pops.reduce(into: [:]) {
                if  case bloc? = $1.region?.bloc {
                    $0[$1.id] = $1.snapshot
                }
            },
            factories: self.state.context.factories.reduce(into: [:]) {
                if  case bloc? = $1.region?.bloc {
                    $0[$1.id] = $1.snapshot
                }
            },
            buildings: self.state.context.buildings.reduce(into: [:]) {
                if  case bloc? = $1.region?.bloc {
                    $0[$1.id] = $1.snapshot
                }
            },
            mines: self.state.context.mines.reduce(into: [:]) {
                if  case bloc? = $1.region?.bloc {
                    $0[$1.state.id] = $1.snapshot
                }
            }
        )

        let cacheReference: Reference<GameUI.Cache> = .init(value: cache)
        self.model.cachePointer.withLock { $0 = cacheReference }
    }
}
extension GameSession {
    public static func load(
        _ save: consuming GameSave,
        rules: borrowing GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        .init(state: try .load(save, rules: rules, map: map))
    }

    public static func load(
        start: consuming GameStart,
        rules: borrowing GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        .init(state: try .load(start: start, rules: rules, map: map))
    }

    public var save: GameSave { self.state.save }
}
extension GameSession {
    public func faster() {
        self.clock.faster()
    }
    public func slower() {
        self.clock.slower()
    }
    public func pause() {
        self.clock.pause()
    }

    public func start() throws {
        try self.state.sync()
        try self.publish()
    }

    public func tick() throws {
        if  self.clock.tick() {
            try self.state.tick()
        }
        try self.publish()
    }
}
extension GameSession {
    public func loadTerrain(from editor: PlanetTileEditor) throws {
        try self.state.context.loadTerrain(from: editor)
    }

    public func editTerrain() async -> PlanetTileEditor? {
        guard
        case (_, let current?) = await self.model.ui.navigator.current,
        let planet: PlanetContext = self.state.context.planets[current.planet],
        let tile: PlanetGrid.Tile = planet.grid.tiles[current.tile] else {
            return nil
        }

        return .init(
            id: tile.id,
            rotate: nil,
            size: planet.grid.size,
            name: tile.name,
            terrain: tile.terrain.symbol,
            terrainChoices: self.state.context.rules.terrains.values.map(\.symbol),
            geology: tile.geology.symbol,
            geologyChoices: self.state.context.rules.geology.values.map(\.symbol)
        )
    }

    public func saveTerrain() -> TerrainMap { self.state.context.saveTerrain() }
}
extension GameSession {
    public nonisolated func call(
        _ action: ContextMenuAction,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws {
        switch action {
        case .SwitchToPlayer:
            self.callSwitchToPlayer(
                try arguments[0].decode(),
            )
        }
    }

    private nonisolated func callSwitchToPlayer(
        _ id: CountryID
    ) {
        let _: Task<Void, Never> = .init {
            await { (self: isolated GameSession) in self.state.context.player = id } (self)
        }
    }
}
