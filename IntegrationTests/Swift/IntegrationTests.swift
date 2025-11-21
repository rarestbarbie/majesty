import Glibc

import GameEngine
import GameIDs
import JavaScriptKit

import JavaScriptInterop
import JavaScriptKit

struct IntegrationTestFile {
    let name: String
    let save: GameSave
}
extension IntegrationTestFile {
    enum ObjectKey: JSString {
        case name
        case save
    }
}
extension IntegrationTestFile: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.name] = self.name
        js[.save] = self.save
    }
}
extension IntegrationTestFile: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            name: try js[.name].decode(),
            save: try js[.save].decode()
        )
    }
}

@main struct IntegrationTests {
    static func main() throws {
        var outputs: [IntegrationTestFile] = []
        defer {
            JSObject.global["outputs"] = outputs.jsValue
        }

        do {
            try Self.HashRules()
        } catch {
            print("Integration test 'HashRules' failed: \(error)")
            exit(1)
        }

        for target: GameDate in [
                .gregorian(year: 2426, month: 1, day: 1),
                .gregorian(year: 2438, month: 1, day: 1)
            ] {
            let save: GameSave
            do {
                save = try Self.HashGameState(target: target)
                print(
                    """
                    Integration test 'HashGameState' passed for target \(target)
                    """
                )
            } catch {
                print(
                    """
                    Integration test 'HashGameState' failed for target \(target): \(error)
                    """
                )
                exit(1)
            }

            outputs.append(
                .init(
                    name: "HashGameState_\(target)",
                    save: save
                )
            )
        }
    }
}
extension IntegrationTests {
    static func HashRules() throws {
        let s1: GameSession = try .reload()
        let s2: GameSession = try .reload()

        print("GameSession 1 rules hash: \(s1.rules.hash)")
        print("GameSession 2 rules hash: \(s2.rules.hash)")

        if  s1.rules.hash != s2.rules.hash {
            throw """
            GameRulesDescription mismatch after reload!
            """ as IntegrationTestFailure
        }
    }
    static func HashGameState(target: GameDate) throws -> GameSave {
        var s1: GameSession = try .reload()
        var s2: GameSession = try .reload()

        let started: SuspendingClock.Instant = .now

        try s1.run(until: target)

        let elapsed: Duration = .now - started

        print("GameSession took \(elapsed) to run until \(target)")

        try s2.run(until: target)

        if  s1._hash != s2._hash {
            throw """
            GameSession mismatch after running until \(target)!
            """ as IntegrationTestFailure
        }

        return s1.save
    }
}
