import GameState
import JavaScriptKit
import JavaScriptInterop

struct PlanetDetails {
    let id: GameID<Planet>
    var open: PlanetDetailsTab
    var grid: PlanetGrid

    init(id: GameID<Planet>, open: PlanetDetailsTab) {
        self.id = id
        self.open = open
        self.grid = .init()
    }
}
extension PlanetDetails {
    mutating func update(in context: GameContext) {
        guard
        let planet: PlanetContext = context.planets[self.id]
        else {
            return
        }

        switch self.open {
        case .Grid: self.grid.update(from: planet, in: context)
        }
    }
}
extension PlanetDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id

        switch self.open {
        case .Grid: js[.open] = self.grid
        }
    }
}
