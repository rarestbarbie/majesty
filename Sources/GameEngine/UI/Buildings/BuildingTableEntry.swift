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

        case y_size = "y_size"
        case z_size = "z_size"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.location] = self.location
        js[.type] = self.type
        js[.y_size] = self.state.y.size
        js[.z_size] = self.state.z.size
    }
}
