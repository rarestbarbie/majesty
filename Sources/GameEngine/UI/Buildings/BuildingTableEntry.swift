import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct BuildingTableEntry {
    let id: BuildingID
    let location: String
    let type: String
    let state: Building
}
extension BuildingTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case location
        case type

        case y_active = "y_active"
        case y_vacant = "y_vacant"
        case z_active = "z_active"
        case z_vacant = "z_vacant"

        case progress
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.location] = self.location
        js[.type] = self.type
        js[.y_active] = self.state.y.active
        js[.y_vacant] = self.state.y.vacant
        js[.z_active] = self.state.z.active
        js[.z_vacant] = self.state.z.vacant
        js[.progress] = self.state.z.fl
    }
}
