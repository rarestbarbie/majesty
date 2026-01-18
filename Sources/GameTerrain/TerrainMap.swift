import JavaScriptInterop

@frozen public struct TerrainMap {
    public let planets: [Planet]
    public let planetSurfaces: [PlanetSurface]

    @inlinable public init(
        planets: [Planet],
        planetSurfaces: [PlanetSurface]
    ) {
        self.planets = planets
        self.planetSurfaces = planetSurfaces
    }
}
extension TerrainMap {
    @frozen public enum ObjectKey: JSString {
        case planets
        case planet_surfaces
    }
}
extension TerrainMap: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.planets] = self.planets
        js[.planet_surfaces] = self.planetSurfaces
    }
}
extension TerrainMap: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            planets: try js[.planets].decode(),
            planetSurfaces: try js[.planet_surfaces].decode()
        )
    }
}
