import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct PlanetDetails {
    let id: Address
    var open: PlanetMapLayer

    private var tile: PlanetGrid.TileSnapshot?

    init(id: Address, focus: Focus) {
        self.id = id
        self.open = focus.layer
        self.tile = nil
    }
}
extension PlanetDetails: PersistentReportDetails {
    mutating func refocus(on focus: Focus) {
        self.open = focus.layer
    }
}
extension PlanetDetails {
    mutating func update(from tile: PlanetGrid.TileSnapshot, in _: borrowing GameUI.Cache) {
        self.tile = tile
    }
}
extension PlanetDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open

        case name
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.open] = self.open
        js[.name] = self.tile?.name
    }
}
