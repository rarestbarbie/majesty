import GameEconomy
import GameEngine
import GameRules
import GameState
import JavaScriptEventLoop
import JavaScriptInterop
import JavaScriptKit
import RealModule

@MainActor
struct GameAPI {
    private let swift: JSObject

    init(swift: JSValue) {
        self.swift = swift.constructor.function!
    }
}

@main
extension GameAPI {
    static var game: GameSession? = nil

    static func main() throws {
        JavaScriptEventLoop.installGlobalExecutor()
        print("JavaScript event loop installed")

        let main: Self = .init(swift: JSObject.global["swift"])
        try main.run()
    }
}
extension GameAPI {
    private func run() throws {
        let (events, stream): (
            AsyncStream<(PlayerEvent, UInt64)>,
            AsyncStream<(PlayerEvent, UInt64)>.Continuation
        ) = AsyncStream<(PlayerEvent, UInt64)>.makeStream()

        self[.start] = {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await Self.handle(events: events, ui: $0)
        }
        self[.call] = { try Self.game?.call($0, with: .init(array: $1)) }
        self[.load] = {
            do {
                Self.game = try .init(save: $0, rules: $1, terrain: $2)
            } catch let error {
                print("Error loading game: \(error)")
            }

            return try Self.game?.start()
        }

        self[.loadTerrain] = { try Self.game?.loadTerrain(from: $0) }
        self[.editTerrain] = { Self.game?.editTerrain() }
        self[.saveTerrain] = { Self.game?.saveTerrain() }

        self[.push] = { stream.yield(($0, $1)) }

        self[.openPlanet] = { try Self.game?.openPlanet(subject: $0, details: $1) }
        self[.openProduction] = { try Self.game?.openProduction(subject: $0, details: $1) }
        self[.openPopulation] = { try Self.game?.openPopulation(subject: $0, details: $1) }
        self[.openTrade] = { try Self.game?.openTrade(subject: $0, filter: $1) }
        self[.closeScreen] = { Self.game?.open(nil) }
        self[.minimap] = { Self.game?.minimap(planet: $0, layer: $1, cell: $2) }
        self[.view] = { try Self.game?.view($0, to: $1) }
        // self[.switch] = { try Self.game?.switch(to: $0) }
        self[.orbit] = { Self.game?.orbit($0) }

        self[.gregorian] = GameDateComponents.init(_:)
        self[.contextMenu] = {
            try Self.game?.contextMenu(type: $0, with: .init(array: $1))
        }
        self[.tooltip] = {
            try Self.game?.tooltip(type: $0, with: .init(array: $1))
        }

        print("Game engine initialized!")
    }

    private static func handle(
        events: AsyncStream<(PlayerEvent, UInt64)>,
        ui: JSValue
    ) async throws {
        print("Starting game loop...")

        var next: UInt64 = 1
        for await (event, i): (PlayerEvent, UInt64) in events {
            if  next == i || i == 0 {
                next += 1
            } else {
                fatalError("OUT OF SYNC! (seq = \(i), expected = \(next))")
            }

            if let state: GameUI = try self.game?.handle(event) {
                _ = ui.update(state)
            }
        }
    }
}
extension GameAPI {
    private subscript<each T>(
        symbol: Symbol
    ) -> (repeat each T) async throws -> () where repeat each T: LoadableFromJSValue {
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
    ) -> (repeat each T) async throws -> sending U where repeat each T: LoadableFromJSValue,
        U: ConvertibleToJSValue {
        get {
            { (_: repeat each T) in fatalError("no implementation provided") }
        }
        nonmutating set(yield) {
            self.register(as: symbol) { (argument: repeat each T) in
                try await yield(repeat each argument).jsValue
            }
        }
    }

    private func register<each T>(
        as symbol: Symbol,
        operation: sending @escaping (repeat each T) async throws -> sending JSValue
    ) where repeat each T: LoadableFromJSValue {
        self.swift["\(symbol)"] = .object(
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
        self.swift["\(symbol)"] = .object(
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
