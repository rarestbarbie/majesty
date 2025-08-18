import GameState
import JavaScriptInterop
import JavaScriptKit

@frozen public struct CelestialOrbit {
    public let orbits: GameID<Planet>
    /// Semi-major axis
    public let a: Double
    /// Eccentricity
    public let e: Double
    /// Inclination, in radians
    public let i: Double
    /// Argument of periapsis, in radians
    public let ω: Double
    /// Longitude of ascending node, in radians
    public let Ω: Double
}
extension CelestialOrbit {
    @frozen public enum ObjectKey: JSString, Sendable {
        case orbits
        case a
        case e
        case i
        case ω
        case Ω
    }
}
extension CelestialOrbit: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.orbits] = self.orbits
        js[.a] = self.a
        js[.e] = self.e
        js[.i] = self.i
        js[.ω] = self.ω
        js[.Ω] = self.Ω
    }
}
extension CelestialOrbit: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            orbits: try js[.orbits].decode(),
            a: try js[.a].decode(),
            e: try js[.e].decode(),
            i: try js[.i].decode(),
            ω: try js[.ω]?.decode() ?? 0,
            Ω: try js[.Ω]?.decode() ?? 0
        )
    }
}
