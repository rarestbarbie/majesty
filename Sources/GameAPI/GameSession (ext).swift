import GameEngine
import GameUI
import JavaScriptInterop

extension GameSession {
    func handle(_ event: PlayerEvent) throws -> GameUI? {
        switch event {
        case .faster:
            self.faster()
        case .slower:
            self.slower()
        case .pause:
            self.pause()
        case .tick:
            return try self.tick()
        }

        return nil
    }
}

/*
Steadfast, Fickle
Impressionistic, Analytical
Thrifty, Generous

Confrontational, Consensual
Wary, Welcoming
Unyielding, Forgiving
Cruel, Impartial, Gentle
*/
