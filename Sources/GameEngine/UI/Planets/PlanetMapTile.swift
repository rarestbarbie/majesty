import Color
import GameIDs
import HexGrids
import JavaScriptInterop

struct PlanetMapTile: Identifiable {
    let id: Address
    let shape: (HexagonPath, HexagonPath?)
    let color: Color?
    let x: Double?
    let y: Double?
    let z: Double?
}
extension PlanetMapTile {
    enum ObjectKey: JSString, Sendable {
        case id
        case d0
        case d1
        case color
        case x
        case y
        case z
    }
}
extension PlanetMapTile: JavaScriptEncodable {
    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.d0] = self.shape.0.d
        js[.d1] = self.shape.1?.d
        js[.color] = self.color
        js[.x] = self.x
        js[.y] = self.y
        js[.z] = self.z
    }
}
