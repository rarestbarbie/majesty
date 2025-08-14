import GameEconomy
import GameEngine
import GameRules
import GameState
import JavaScriptEventLoop
import JavaScriptInterop
import JavaScriptKit
import RealModule

struct GameAPI {
    private let swift: JSFunction
    private let ui: JSValue

    init(swift: JSValue, ui: JSValue) {
        self.swift = swift.constructor.function!
        self.ui = ui
    }
}

@main
extension GameAPI {
    static func main() async throws {
        let main: Self = .init(swift: JSObject.global["swift"], ui: JSObject.global["ui"])
        try await main.run()
    }
}
extension GameAPI {
    private func run() async throws {
        JavaScriptEventLoop.installGlobalExecutor()

        let (events, stream): (
            AsyncStream<(PlayerEvent, UInt64)>,
            AsyncStream<(PlayerEvent, UInt64)>.Continuation
        ) = AsyncStream<(PlayerEvent, UInt64)>.makeStream()

        var game: GameSession? = nil

        self[.load] = {
            do {
                var new: GameSession = try .init(save: $0, rules: $1, terrain: $2)
                self.update(ui: try new.start())
                game = consume new
                return true
            } catch (let error) {
                print("Error loading game: \(error)")
                return false
            }
        }
        self[.loadTerrain] = { try game?.loadTerrain(from: $0) }
        self[.editTerrain] = { game?.editTerrain() }
        self[.saveTerrain] = { game?.saveTerrain() }

        self[.push] = { stream.yield(($0, $1)) }

        self[.openPlanet] = { try game?.openPlanet(subject: $0, details: $1) }
        self[.openProduction] = { try game?.openProduction(subject: $0, details: $1) }
        self[.openPopulation] = { try game?.openPopulation(subject: $0) }
        self[.openTrade] = { try game?.openTrade(subject: $0, filter: $1) }
        self[.closeScreen] = { game?.open(nil) }
        self[.focusPlanet] = { game?.focusPlanet($0, cell: $1) }
        self[.view] = { try game?.view($0, to: $1) }
        self[.switch] = {
            if let ui: GameUI = try game?.switch(to: $0) {
                self.update(ui: ui)
            }
        }
        self[.orbit] = { game?.orbit($0) }

        self[.gregorian] = GameDateComponents.init(_:)
        self[.tooltip] = {
            try game?.tooltip(type: $0, with: .init(array: $1))
        }

        var next: UInt64 = 1
        for await (event, i): (PlayerEvent, UInt64) in events {
            if  next == i || i == 0 {
                next += 1
            } else {
                fatalError("OUT OF SYNC! (seq = \(i), expected = \(next))")
            }

            if let ui: GameUI = try game?.handle(event) {
                self.update(ui: ui)
            }
        }
    }

    private func update(ui: GameUI) {
        _ = self.ui.update(ui)
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
            self.swift["\(symbol)"] = .function(JSClosure.init {
                var arguments: Arguments = .init(list: $0)
                do {
                    try yield(
                        repeat try arguments.next(as: (each T).self)
                    )
                } catch let error {
                    print("Error in '\(symbol)': \(error)")
                    //let error: JSObject = JSError.constructor!.new("\(error)")
                }

                return .undefined
            })
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
            self.swift["\(symbol)"] = .function(JSClosure.init {
                var arguments: Arguments = .init(list: $0)
                do {
                    let result: U = try yield(
                        repeat try arguments.next(as: (each T).self)
                    )
                    return result.jsValue
                } catch let error {
                    print("Error in '\(symbol)': \(error)")
                    //let error: JSObject = JSError.constructor!.new("\(error)")
                    return .undefined
                }
            })
        }
    }
}
