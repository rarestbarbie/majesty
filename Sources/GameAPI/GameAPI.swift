import GameEconomy
import GameEngine
import GameIDs
import GameRules
import GameState
import JavaScriptEventLoop
import JavaScriptInterop
import JavaScriptKit
import RealModule

typealias DefaultExecutorFactory = JavaScriptEventLoop

@MainActor struct GameAPI {
    private static var game: GameSession? = nil

    private let metatype: JSObject
    private let success: ((any ConvertibleToJSValue...) -> JSValue)
    private let tick: ((any ConvertibleToJSValue...) -> JSValue)
    private let draw: ((any ConvertibleToJSValue...) -> JSValue)

    private nonisolated let heartbeat: (
        events: AsyncStream<Void>,
        stream: AsyncStream<Void>.Continuation
    )
    private nonisolated let renderer: (
        events: AsyncStream<Void>,
        stream: AsyncStream<Void>.Continuation
    )

    init(swift: JSValue) {
        guard case .object(let instance) = swift else {
            fatalError("Missing binding for 'window.swift'")
        }

        guard
        let metatype: JSObject = instance.constructor.function,
        let success: ((any ConvertibleToJSValue...) -> JSValue) = instance.success,
        let tick: ((any ConvertibleToJSValue...) -> JSValue) = instance.tick,
        let draw: ((any ConvertibleToJSValue...) -> JSValue) = instance.draw else {
            fatalError("Missing binding in 'window.swift'")
        }

        self.metatype = metatype
        self.success = success
        self.tick = tick
        self.draw = draw

        (
            self.heartbeat.events,
            self.heartbeat.stream
        ) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
        (
            self.renderer.events,
            self.renderer.stream
        ) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
    }
}

@main extension GameAPI {
    static func main() async throws {
        let main: Self = .init(swift: JSObject.global["swift"])
        try await main.run()
    }
}
extension GameAPI {
    private static var ui: GameUI.Model? { self.game?.model }

    private func run() async throws {
        let (events, stream): (
            AsyncStream<(PlayerEvent, UInt64)>,
            AsyncStream<(PlayerEvent, UInt64)>.Continuation
        ) = AsyncStream<(PlayerEvent, UInt64)>.makeStream()

        let (frames, browser): (
            AsyncStream<Reference<GameUI>>,
            AsyncStream<Reference<GameUI>>.Continuation
        ) = AsyncStream<Reference<GameUI>>.makeStream(bufferingPolicy: .bufferingNewest(1))

        let executor: WebWorkerTaskExecutor = try await .init(numberOfThreads: 4)
        defer {
            executor.terminate()
        }

        self.setup(stream: stream)

        print("Game engine initialized!")
        _ = self.success()

        print("Game engine launched!")
        let _: Task<Void, any Error> = .init(executorPreference: executor) {
            try await self.handle(events: events)
        }
        let _: Task<Void, any Error> = .init(executorPreference: executor) {
            try await self.render(browser: browser)
        }

        async
        let _: Void = self.heartbeats()

        for await frame: Reference<GameUI> in frames {
            _ = self.draw(frame.value)
        }
    }
    private func setup(stream: AsyncStream<(PlayerEvent, UInt64)>.Continuation) {
        self[.call] = { try Self.game?.call($0, with: .init(array: $1)) }
        self[.save] = { await Self.game?.save }
        self[.load] = {
            guard case nil = Self.game else {
                print("A game is already loaded!")
                return false
            }

            do {
                Self.game = try .load(start: $0, rules: $1, map: $2)
                try await Self.game?.start()
                return true
            } catch let error {
                print("Error loading game: \(error)")
                return false
            }
        }

        self[.loadTerrain] = { try await Self.game?.loadTerrain(from: $0) }
        self[.editTerrain] = { await Self.game?.editTerrain() }
        self[.saveTerrain] = { await Self.game?.saveTerrain() }

        self[.push] = { stream.yield(($0, $1)) }

        self[.openPlanet] = { try await Self.ui?.openPlanet($0) }
        self[.openInfrastructure] = { try await Self.ui?.openInfrastructure($0) }
        self[.openProduction] = { try await Self.ui?.openProduction($0) }
        self[.openPopulation] = { try await Self.ui?.openPopulation($0) }
        self[.openTrade] = { try await Self.ui?.openTrade($0) }
        self[.closeScreen] = { await Self.ui?.open(nil) }
        self[.minimap] = { await Self.ui?.minimap(planet: $0, layer: $1, cell: $2) }
        self[.view] = { try await Self.ui?.view($0, to: $1) }

        self[.gregorian] = GameDateComponents.init(_:)
        self[.contextMenu] = { try Self.ui?.contextMenu(type: $0, with: .init(array: $1)) }
        self[.tooltip] = { try Self.ui?.tooltip(type: $0, with: .init(array: $1)) }
        self[.orbit] = { Self.ui?.orbit($0) }
    }

    private func heartbeats() async throws {
        for await _: () in self.heartbeat.events {
            _ = self.tick()
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    private nonisolated func handle(
        events: AsyncStream<(PlayerEvent, UInt64)>,
    ) async throws {
        print("Starting game loop...")

        var game: GameSession? = nil
        var next: UInt64 = 1
        for await (event, i): (PlayerEvent, UInt64) in events {
            if  next == i || i == 0 {
                next += 1
            } else {
                fatalError("OUT OF SYNC! (seq = \(i), expected = \(next))")
            }

            // avoid awaiting on main actor if game has already been loaded
            if case nil = game {
                game = await Self.game
            }

            switch event {
            case .faster:
                await game?.faster()
            case .slower:
                await game?.slower()
            case .pause:
                await game?.pause()
            case .tick:
                try await game?.tick()
                // we must yield to the heartbeat stream even if the game is not yet loaded,
                // otherwise we won’t get a new heartbeat to continue the loop
                self.heartbeat.stream.yield()
            }

            self.renderer.stream.yield()
        }
    }

    private nonisolated func render(
        browser: AsyncStream<Reference<GameUI>>.Continuation
    ) async throws {
        var ui: GameUI.Model? = nil
        for await _: () in self.renderer.events {
            if case nil = ui {
                ui = await Self.ui
            }
            guard
            let ui: GameUI.Model else {
                continue
            }

            browser.yield(try await ui.sync())
        }
    }
}
extension GameAPI {
    private subscript<each T>(
        symbol: Symbol
    ) -> (repeat each T) async throws -> () where repeat each T: LoadableFromJSValue & Sendable {
        get {
            { (_: repeat each T) in fatalError("no implementation provided") }
        }
        nonmutating set(yield) {
            self.register(as: symbol) { (argument: repeat each T) in
                try await yield(repeat each argument)
                return .undefined
            }
        }
    }
    private subscript<each T, U>(
        symbol: Symbol
    ) -> (repeat each T) async throws -> sending U
        where repeat each T: LoadableFromJSValue & Sendable,
        U: ConvertibleToJSValue & SendableMetatype {
        get {
            { (_: repeat each T) in fatalError("no implementation provided") }
        }
        nonmutating set(yield) {
            self.register(as: symbol) { (argument: repeat each T) -> sending JSValue in
                try await yield(repeat each argument).jsValue
            }
        }
    }

    private func register<each T>(
        as symbol: Symbol,
        operation: sending @escaping (repeat each T) async throws -> sending JSValue
    ) where repeat each T: LoadableFromJSValue & Sendable {
        self.metatype["\(symbol)"] = .object(
            JSClosure.async {
                var arguments: Arguments = .init(list: $0)
                do {
                    return try await operation(
                        repeat try arguments.next(as: (each T).self)
                    )
                } catch let error {
                    print("Error in '\(symbol)': \(error)")
                    //let error: JSObject = JSError.constructor!.new("\(error)")
                    return .undefined
                }
            }
        )
    }
}
extension GameAPI {
    private subscript<each T>(
        symbol: Symbol
    ) -> (repeat each T) throws -> () where repeat each T: LoadableFromJSValue {
        get {
            { (_: repeat each T) in fatalError("no implementation provided") }
        }
        nonmutating set(yield) {
            self.register(as: symbol) { (argument: repeat each T) in
                try yield(repeat each argument)
                return .undefined
            }
        }
    }

    private subscript<each T, U>(
        symbol: Symbol
    ) -> (repeat each T) throws -> U where repeat each T: LoadableFromJSValue,
        U: ConvertibleToJSValue {
        get {
            { (_: repeat each T) in fatalError("no implementation provided") }
        }
        nonmutating set(yield) {
            self.register(as: symbol) { (argument: repeat each T) in
                try yield(repeat each argument).jsValue
            }
        }
    }

    private func register<each T>(
        as symbol: Symbol,
        operation: @escaping (repeat each T) throws -> JSValue
    ) where repeat each T: LoadableFromJSValue {
        self.metatype["\(symbol)"] = .object(
            JSClosure.init {
                do {
                    var arguments: Arguments = .init(list: $0)
                    return try operation(
                        repeat try arguments.next(as: (each T).self)
                    )
                } catch let error {
                    print("Error in '\(symbol)': \(error)")
                    //let error: JSObject = JSError.constructor!.new("\(error)")
                    return .undefined
                }
            }
        )
    }
}
