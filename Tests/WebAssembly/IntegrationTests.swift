@_spi(testable) import GameEngine
import GameIDs

@main struct IntegrationTests {
    static func main() throws {
        for target: GameDate in [
                .gregorian(year: 2427, month: 1, day: 1),
                // .gregorian(year: 2438, month: 1, day: 1)
            ] {
            do {
                try Self.HashGameState(target: target)
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
        }
    }
}
extension IntegrationTests {
    static func HashGameState(target: GameDate) throws {
        var state: GameSession.State = try .reload()
        let clock: SuspendingClock = .init()
        let runtime: Duration = try clock.measure {
            try state.run(until: target)
        }

        print("GameSession took \(runtime) to run until \(target)")
    }
}
