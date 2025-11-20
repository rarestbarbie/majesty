import GameRules
import GameIDs
import GameTerrain
import HexGrids
import JavaScriptKit
import JavaScriptInterop

public struct PlanetTileEditor {
    let id: Address

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
        // encoded separately, to make it easier for the frontend to tell if we are editing a
        // polar tile (otherwise it would have to parse the ID)
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
        js[.id] = self.id.tile
        js[.on] = self.id.planet
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
            id: try js[.on].decode() / js[.id].decode(),
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
