import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension Planet {
    @frozen public struct Orbit {
        public let orbits: PlanetID
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
}
extension Planet.Orbit {
    @frozen public enum ObjectKey: JSString, Sendable {
        case orbits
        case a
        case e
        case i
        case ω
        case Ω
    }
}
extension Planet.Orbit: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.orbits] = self.orbits
        js[.a] = self.a
        js[.e] = self.e
        js[.i] = self.i
        js[.ω] = self.ω
        js[.Ω] = self.Ω
    }
}
extension Planet.Orbit: JavaScriptDecodable {
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
