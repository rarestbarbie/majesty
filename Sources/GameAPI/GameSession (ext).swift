import GameEngine
import GameUI
import JavaScriptInterop

extension GameSession {
    func handle(_ event: PlayerEvent) throws {
        switch event {
        case .faster:
            self.faster()
        case .slower:
            self.slower()
        case .pause:
            self.pause()
        case .tick:
            try self.tick()
        }
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
