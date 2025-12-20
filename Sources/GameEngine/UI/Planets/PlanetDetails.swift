import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct PlanetDetails {
    let id: PlanetID
    var open: PlanetDetailsTab
    var grid: PlanetMap

    init(id: PlanetID, open: PlanetDetailsTab) {
        self.id = id
        self.open = open
        self.grid = .init()
    }
}
extension PlanetDetails {
    mutating func update(in cache: borrowing GameUI.Cache) {
        guard
        let planet: PlanetSnapshot = cache.planets[self.id] else {
            return
        }

        switch self.open {
        case .Grid: self.grid.update(from: planet, in: cache)
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
