@_spi(testable) import GameEngine
import GameIDs
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

        for target: GameDate in [
                .gregorian(year: 2427, month: 1, day: 1),
                // .gregorian(year: 2438, month: 1, day: 1)
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
                fatalError(
                    """
                    Integration test 'HashGameState' failed for target \(target): \(error)
                    """
                )
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
    static func HashGameState(target: GameDate) throws -> GameSave {
        var s1: GameSession.State = try .reload()
        var s2: GameSession.State = try .reload()

        let clock: SuspendingClock = .init()
        let t1: Duration = try clock.measure {
            try s1.run(until: target)
        }

        print("GameSession took \(t1) to run until \(target)")

        let t2: Duration = try clock.measure {
            try s2.run(until: target)
        }

        print("GameSession took \(t2) to run until \(target)")

        if  s1._hash != s2._hash {
            throw """
            GameSession mismatch after running until \(target)!
            """ as IntegrationTestFailure
        }

        return s1.save
    }
}
