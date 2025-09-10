import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PlanetTile {
    public let name: String?
    public let resources: Set<Resource>

    public init(
        name: String? = nil,
        resources: Set<Resource> = []
    ) {
        self.name = name
        self.resources = resources
    }
}
extension PlanetTile {
    @frozen public enum ObjectKey: JSString {
        case name
        case resources
    }
}
extension PlanetTile: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.name] = self.name
        js[.resources] = self.resources.isEmpty ? nil : self.resources.sorted()
    }
}
extension PlanetTile: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            name: try js[.name]?.decode(),
            resources: .init(try js[.resources]?.decode() ?? [])
        )
    }
}
