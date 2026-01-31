import GameEconomy
import GameUI
import JavaScriptInterop

struct MarketTableEntry: Identifiable {
    let id: WorldMarket.ID
    let name: String
    let open: Double
    let close: Double
    let volume: Delta<Double>
    let velocity: Delta<Double>
}
extension MarketTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case open
        case close

        case volume_y
        case volume_z

        case velocity_y
        case velocity_z
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.open] = self.open
        js[.close] = self.close
        js[.volume_y] = self.volume.y
        js[.volume_z] = self.volume.z
        js[.velocity_y] = self.velocity.y
        js[.velocity_z] = self.velocity.z
    }
}
