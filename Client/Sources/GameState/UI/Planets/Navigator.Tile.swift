import GameEngine
import JavaScriptInterop
import JavaScriptKit

extension Navigator {
    @frozen @usableFromInline struct Tile {
        let id: HexCoordinate
        let name: String?
        let terrain: String
    }
}
extension Navigator.Tile: JavaScriptEncodable {
    @frozen @usableFromInline enum ObjectKey: JSString, Sendable {
        case id
        case name
        case terrain
    }

    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.terrain] = self.terrain
    }
}
