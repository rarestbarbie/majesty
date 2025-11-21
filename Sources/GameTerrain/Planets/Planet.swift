import Color
import GameIDs
import JavaScriptInterop
import JavaScriptKit

/// In Majesty, everything is a planet, even stars and moons.
@frozen public struct Planet: Identifiable {
    public let id: PlanetID
    public let name: String
    public let type: PlanetType
    public let color: Color
    public let orbit: Orbit?
    public let opposes: PlanetID?
    public let mass: Double
    public let tilt: Double?
    public let radius: Double
    public let sprite: (x: Int, y: Int, size: Int, disk: Double)
}

extension Planet {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case name
        case type
        case color
        case orbit
        case opposes
        case mass
        case tilt
        case radius
        case sprite_x
        case sprite_y
        case sprite_size
        case sprite_disk
    }
}
extension Planet: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.type] = self.type
        js[.color] = self.color
        js[.orbit] = self.orbit
        js[.opposes] = self.opposes
        js[.mass] = self.mass
        js[.tilt] = self.tilt
        js[.radius] = self.radius
        js[.sprite_x] = self.sprite.x
        js[.sprite_y] = self.sprite.y
        js[.sprite_size] = self.sprite.size
        js[.sprite_disk] = self.sprite.disk
    }
}
extension Planet: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name].decode(),
            type: try js[.type].decode(),
            color: try js[.color].decode(),
            orbit: try js[.orbit]?.decode(),
            opposes: try js[.opposes]?.decode(),
            mass: try js[.mass].decode(),
            tilt: try js[.tilt]?.decode(),
            radius: try js[.radius].decode(),
            sprite: (
                x: try js[.sprite_x].decode(),
                y: try js[.sprite_y].decode(),
                size: try js[.sprite_size].decode(),
                disk: try js[.sprite_disk].decode()
            )
        )
    }
}
