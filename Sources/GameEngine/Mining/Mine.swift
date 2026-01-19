import GameIDs
import GameRules
import GameState
import JavaScriptInterop

struct Mine {
    let id: MineID
    let type: MineType
    let tile: Address
    var last: Expansion?

    var y: Dimensions
    var z: Dimensions
}
extension Mine: Sectionable {
    init(id: MineID, section: Section) {
        self.init(
            id: id,
            type: section.type,
            tile: section.tile,
            last: nil,
            y: .init(),
            z: .init()
        )
    }

    var section: Section {
        .init(type: self.type, tile: self.tile)
    }
}
extension Mine: Turnable {
    mutating func turn() {
    }
}
extension Mine: Deletable {
    var dead: Bool { self.z.size <= 0 }
}
extension Mine {
    enum ObjectKey: JSString, Sendable {
        case id
        case type
        case tile
        case last_date
        case last_size

        case y
        case z
    }
}
extension Mine: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type
        js[.last_date] = self.last?.date
        js[.last_size] = self.last?.size

        js[.y] = self.y
        js[.z] = self.z
    }
}
extension Mine: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = try js[.z]?.decode() ?? .init()

        let last: Expansion?
        if  let size: Int64 = try js[.last_size]?.decode() {
            last = .init(size: size, date: try js[.last_date].decode())
        } else {
            last = nil
        }
        self.init(
            id: try js[.id].decode(),
            type: try js[.type].decode(),
            tile: try js[.tile].decode(),
            last: last,
            y: try js[.y]?.decode() ?? today,
            z: today
        )
    }
}
#if TESTABLE
extension Mine: Equatable, Hashable {}
#endif
