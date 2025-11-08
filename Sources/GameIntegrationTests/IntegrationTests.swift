import GameEngine
import GameIDs
import JavaScriptKit

@main struct IntegrationTests {
    static func main() throws {
        do {
            try Self.HashRules()
        } catch {
            print("Integration test 'HashRules' failed: \(error)")
        }

        for year: Int32 in [
            2426,
            // 2450
        ] {
            let target: GameDate = .gregorian(year: year, month: 1, day: 1)
            do {
                try Self.HashGameState(target: target)
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
            }
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
    static func HashGameState(target: GameDate) throws {
        var s1: GameSession = try .reload()
        var s2: GameSession = try .reload()

        try s1.run(until: target)
        try s2.run(until: target)

        if  s1._hash != s2._hash {
            throw """
            GameSession mismatch after running until \(target)!
            """ as IntegrationTestFailure
        }
    }
}
