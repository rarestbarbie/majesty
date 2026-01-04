import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct PlanetDetails {
    let id: Address
    var open: PlanetDetailsTab

    init(id: Address, focus: Focus) {
        self.id = id
        self.open = focus.tab
    }
}
extension PlanetDetails: PersistentReportDetails {
    mutating func refocus(on focus: Focus) {
        self.open = focus.tab
    }
}
extension PlanetDetails {
    mutating func update(from tile: PlanetGrid.TileSnapshot, in _: borrowing GameUI.Cache) {
    }
}
extension PlanetDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
    }
}
