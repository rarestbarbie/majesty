import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct Tile: Identifiable {
    let id: Address
    let type: TileType
    var name: String?

    init(
        id: Address,
        type: TileType,
        name: String?
    ) {
        self.id = id
        self.type = type
        self.name = name
    }
}
extension Tile {
    enum ObjectKey: JSString, Sendable {
        case id
        case ecology
        case geology
        case name
    }
}
extension Tile: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<Tile.ObjectKey>) {
        js[.id] = self.id
        js[.ecology] = self.type.ecology
        js[.geology] = self.type.geology
        js[.name] = self.name
    }
}
extension Tile: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<Tile.ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            type: .init(
                ecology: try js[.ecology].decode(),
                geology: try js[.geology].decode()
            ),
            name: try js[.name]?.decode()
        )
    }
}
