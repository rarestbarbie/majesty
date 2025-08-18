import HexGrids
import JavaScriptInterop
import JavaScriptKit

extension PlanetSurface {
    @frozen @usableFromInline struct Cell {
        let id: HexCoordinate
        let type: String
        let tile: PlanetTile
    }
}
extension PlanetSurface.Cell {
    @frozen @usableFromInline enum ObjectKey: JSString {
        case id
        case type
        case tile
    }
}
extension PlanetSurface.Cell: JavaScriptEncodable {
    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.type] = self.type
        js[.tile] = self.tile
    }
}
extension PlanetSurface.Cell: JavaScriptDecodable {
    @usableFromInline init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            type: try js[.type].decode(),
            tile: try js[.tile]?.decode() ?? .init(),
        )
    }
}
