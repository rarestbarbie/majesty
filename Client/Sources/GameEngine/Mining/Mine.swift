import GameIDs
import GameRules
import GameState
import JavaScriptInterop
import JavaScriptKit

struct Mine {
    let id: MineID
    let type: MineType
    let tile: Address
    var efficiency: Double

    var yesterday: Dimensions
    var today: Dimensions
}
extension Mine: Sectionable {
    init(id: MineID, section: Section) {
        self.init(
            id: id,
            type: section.type,
            tile: section.tile,
            efficiency: 1,
            yesterday: .init(),
            today: .init()
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
    var dead: Bool { self.today.size <= 0 }
}
extension Mine {
    enum ObjectKey: JSString, Sendable {
        case id
        case type
        case tile
        case efficiency

        case y_size

        case t_size
    }
}
extension Mine: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type
        js[.efficiency] = self.efficiency

        js[.y_size] = self.yesterday.size

        js[.t_size] = self.today.size
    }
}
extension Mine: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = .init(
            size: try js[.t_size].decode(),
        )
        self.init(
            id: try js[.id].decode(),
            type: try js[.type].decode(),
            tile: try js[.tile].decode(),
            efficiency: try js[.efficiency].decode(),
            yesterday: .init(
                size: try js[.y_size]?.decode() ?? today.size,
            ),
            today: today
        )
    }
}
#if TESTABLE
extension Mine: Equatable, Hashable {}
#endif
