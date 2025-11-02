import GameIDs
import GameRules
import GameState
import JavaScriptInterop
import JavaScriptKit

struct Mine {
    let id: MineID
    let type: MineType
    let tile: Address
    var size: Int64
}
extension Mine: Sectionable {
    init(id: MineID, section: Section) {
        self.init(
            id: id,
            type: section.type,
            tile: section.tile,
            size: 0
        )
    }

    var section: Section {
        .init(type: self.type, tile: self.tile)
    }
}
extension Mine: Deletable {
    var dead: Bool { self.size <= 0 }
}
extension Mine {
    enum ObjectKey: JSString, Sendable {
        case id
        case type
        case tile
        case size
    }
}
extension Mine: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type
        js[.size] = self.size
    }
}
extension Mine: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            type: try js[.type].decode(),
            tile: try js[.tile].decode(),
            size: try js[.size].decode()
        )
    }
}
#if TESTABLE
extension Mine: Equatable, Hashable {}
#endif
