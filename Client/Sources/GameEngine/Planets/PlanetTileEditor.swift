import GameRules
import GameState
import GameTerrain
import HexGrids
import JavaScriptKit
import JavaScriptInterop

public struct PlanetTileEditor {
    let id: HexCoordinate
    let on: PlanetID

    let rotate: HexRotation?
    let size: Int8
    let name: String?

    let terrain: Symbol
    let terrainChoices: [Symbol]

    let geology: Symbol
    let geologyChoices: [Symbol]
}
extension PlanetTileEditor {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case on
        case rotate
        case size
        case name
        case terrain
        case terrainChoices
        case geology
        case geologyChoices
    }
}
extension PlanetTileEditor: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.on] = self.on
        js[.rotate] = self.rotate
        js[.size] = self.size
        js[.name] = self.name
        js[.terrain] = self.terrain
        js[.terrainChoices] = self.terrainChoices
        js[.geology] = self.geology
        js[.geologyChoices] = self.geologyChoices
    }
}
extension PlanetTileEditor: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            on: try js[.on].decode(),
            rotate: try js[.rotate]?.decode(),
            size: try js[.size].decode(),
            name: try js[.name]?.decode(),
            terrain: try js[.terrain].decode(),
            terrainChoices: try js[.terrainChoices].decode(),
            geology: try js[.geology].decode(),
            geologyChoices: try js[.geologyChoices].decode()
        )
    }
}
