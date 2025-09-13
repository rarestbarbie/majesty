import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PlanetTile {
    public let name: String?
    public let geology: String?

    public init(
        name: String? = nil,
        geology: String? = nil
    ) {
        self.name = name
        self.geology = geology
    }
}
extension PlanetTile {
    @frozen public enum ObjectKey: JSString {
        case name
        case geology
    }
}
extension PlanetTile: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.name] = self.name
        js[.geology] = self.geology
    }
}
extension PlanetTile: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            name: try js[.name]?.decode(),
            geology: try js[.geology]?.decode()
        )
    }
}
