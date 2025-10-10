import Color
import GameIDs
import JavaScriptKit
import JavaScriptInterop
import Vector

struct CelestialBody {
    let id: PlanetID
    let at: Vector3

    let name: String
    let size: Double
    let color: Color
    let sprite: (x: Int, y: Int, size: Int, disk: Double)
}
extension CelestialBody: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case at

        case name
        /// Size relative to the primary body.
        case size
        case color
        case sprite_x
        case sprite_y
        case sprite_size
        case sprite_disk
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.at] = self.at
        js[.name] = self.name
        js[.size] = self.size
        js[.color] = self.color
        js[.sprite_x] = self.sprite.x
        js[.sprite_y] = self.sprite.y
        js[.sprite_size] = self.sprite.size
        js[.sprite_disk] = self.sprite.disk
    }
}
