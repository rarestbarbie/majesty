import GameEconomy
import GameIDs
import JavaScriptInterop

struct BuildingTableEntry: Identifiable {
    let id: BuildingID
    let location: String
    let type: String
    let y: Building.Dimensions
    let z: Building.Dimensions
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
        js[.y_active] = self.y.active
        js[.y_vacant] = self.y.vacant
        js[.z_active] = self.z.active
        js[.z_vacant] = self.z.vacant
        js[.progress] = self.z.fl
    }
}
