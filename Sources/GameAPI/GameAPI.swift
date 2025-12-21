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
    private let instance: JSValue
    private let metatype: JSObject

    init(swift: JSValue) {
        self.instance = swift
        self.metatype = swift.constructor.function!
    }
}

@main extension GameAPI {
    private static var application: JSValue? = nil
    private static var game: GameSession? = nil

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

        let (render, renderer): (
            AsyncStream<Void>,
            AsyncStream<Void>.Continuation
        ) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(0))

        let (frames, browser): (
            AsyncStream<Reference<GameUI>>,
            AsyncStream<Reference<GameUI>>.Continuation
        ) = AsyncStream<Reference<GameUI>>.makeStream(bufferingPolicy: .bufferingNewest(0))

        let executor: WebWorkerTaskExecutor = try await .init(numberOfThreads: 4)
        defer {
            executor.terminate()
        }

        self.setup(stream: stream)

        print("Game engine initialized!")
        _ = self.instance.success()

        print("Game engine launched!")
        let _: Task<Void, any Error> = .init(executorPreference: executor) {
            try await self.handle(events: events, renderer: renderer)
        }
        let _: Task<Void, any Error> = .init(executorPreference: executor) {
            try await Self.render(events: render, browser: browser)
        }

        for await frame: Reference<GameUI> in frames {
            print("Rendering frame...")
            _ = Self.application?.update(frame.value)
        }
    }
    private func setup(stream: AsyncStream<(PlayerEvent, UInt64)>.Continuation) {
        self[.bind] = { Self.application = $0 }
        self[.call] = { try Self.game?.call($0, with: .init(array: $1)) }
        self[.save] = { await Self.game?.save }
        self[.load] = {
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

    private func handle(
        events: AsyncStream<(PlayerEvent, UInt64)>,
        renderer: AsyncStream<Void>.Continuation
    ) async throws {
        print("Starting game loop...")

        var next: UInt64 = 1
        for await (event, i): (PlayerEvent, UInt64) in events {
            if  next == i || i == 0 {
                next += 1
            } else {
                fatalError("OUT OF SYNC! (seq = \(i), expected = \(next))")
            }

            switch event {
            case .faster:
                await Self.game?.faster()
            case .slower:
                await Self.game?.slower()
            case .pause:
                await Self.game?.pause()
            case .tick:
                try await Self.game?.tick()
                _ = self.instance.tickProcessed()
            }

            renderer.yield()
        }
    }

    private static func render(
        events: AsyncStream<Void>,
        browser: AsyncStream<Reference<GameUI>>.Continuation
    ) async throws {
        for await _: () in events {
            if  let ui: Reference<GameUI> = try await self.ui?.sync() {
                browser.yield(ui)
            }
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
