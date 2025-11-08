import GameEngine
import GameIDs
import GameRules
import JavaScriptKit

@main struct Main {
    static func main() throws {
        #if TESTABLE
        let target: GameDate = .gregorian(year: 2475, month: 1, day: 1)

        var s1: GameSession = try .init(
            save: try .load(from: JSObject.global["start"]),
            rules: try .load(from: JSObject.global["rules"]),
            terrain: try .load(from: JSObject.global["terrain"]),
        )
        var s2: GameSession = try .init(
            save: try .load(from: JSObject.global["start"]),
            rules: try .load(from: JSObject.global["rules"]),
            terrain: try .load(from: JSObject.global["terrain"]),
        )

        print("GameSession 1 rules hash: \(s1.rules.hash)")
        print("GameSession 2 rules hash: \(s2.rules.hash)")

        try s1.run(until: target)
        try s2.run(until: target)

        print("GameSession 1 hash: \(s1._hash)")
        print("GameSession 2 hash: \(s2._hash)")

        if  s1 != s2 {
            print(
                """
                GameSession mismatch after running until \(target)!
                """
            )
        }
        #endif
    }
}
