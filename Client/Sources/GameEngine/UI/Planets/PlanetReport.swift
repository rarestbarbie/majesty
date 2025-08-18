import GameEconomy
import GameState
import JavaScriptKit
import JavaScriptInterop

public struct PlanetReport {
    private var planet: PlanetDetails?

    init() {
        self.planet = nil
    }
}
extension PlanetReport: PersistentReport {
    mutating func select(
        subject: GameID<Planet>?,
        details: PlanetDetailsTab?,
        filter: Never?
    ) {
        if  let subject: GameID<Planet> {
            self.planet = .init(id: subject, open: .Grid)
        }
        if  let details: PlanetDetailsTab {
            self.planet?.open = details
        }
    }

    mutating func update(on map: borrowing GameMap, in context: GameContext) {
        self.planet?.update(in: context)
    }
}
extension PlanetReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case planet
    }
}
extension PlanetReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Planet
        js[.planet] = self.planet
    }
}
