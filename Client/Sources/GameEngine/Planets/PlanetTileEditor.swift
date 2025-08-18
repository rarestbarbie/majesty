import GameRules
import GameState
import HexGrids
import JavaScriptKit
import JavaScriptInterop

public struct PlanetTileEditor {
    let id: HexCoordinate
    let on: GameID<Planet>

    let rotate: HexRotation?
    let size: Int8
    let tile: PlanetTile
    let type: TerrainType

    let terrainLabels: [String]
    let terrainChoices: [TerrainType]
}
extension PlanetTileEditor {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case on
        case rotate
        case size
        case tile
        case type
        case terrainLabels
        case terrainChoices
    }
}
extension PlanetTileEditor: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.on] = self.on
        js[.rotate] = self.rotate
        js[.size] = self.size
        js[.tile] = self.tile
        js[.type] = self.type
        js[.terrainLabels] = self.terrainLabels
        js[.terrainChoices] = self.terrainChoices
    }
}
extension PlanetTileEditor: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            on: try js[.on].decode(),
            rotate: try js[.rotate]?.decode(),
            size: try js[.size].decode(),
            tile: try js[.tile].decode(),
            type: try js[.type].decode(),
            terrainLabels: try js[.terrainLabels].decode(),
            terrainChoices: try js[.terrainChoices].decode()
        )
    }
}
