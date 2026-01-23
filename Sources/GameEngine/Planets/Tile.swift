import GameIDs
import JavaScriptInterop
import DequeModule

extension Tile {
    typealias Dimensions = Never?
}

struct Tile: Identifiable {
    let id: Address
    let type: TileType
    var name: String?

    var y: Interval
    var z: Dimensions
    var history: Deque<Aggregate>

    init(
        id: Address,
        type: TileType,
        name: String?,
        y: Interval,
        z: Dimensions,
        history: Deque<Tile.Aggregate>
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.y = y
        self.z = z
        self.history = history
    }
}
extension Tile {
    init(
        id: Address,
        type: TileType,
        name: String?,
    ) {
        self.init(
            id: id,
            type: type,
            name: name,
            y: .init(stats: .init(), state: nil),
            z: nil,
            history: []
        )
    }
}
extension Tile {
    enum ObjectKey: JSString, Sendable {
        case id
        case ecology
        case geology
        case name
        case y_stats = "yc"
        case y_state = "y"
        case z_state = "z"
        case history
    }
}
extension Tile: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<Tile.ObjectKey>) {
        js[.id] = self.id
        js[.ecology] = self.type.ecology
        js[.geology] = self.type.geology
        js[.name] = self.name
        js[.y_stats] = self.y.stats
        js[.y_state] = self.y.state
        js[.z_state] = self.z
        js[.history] = self.history
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
            name: try js[.name]?.decode(),
            y: .init(
                stats: try js[.y_stats].decode(),
                state: try js[.y_state].decode()
            ),
            z: try js[.z_state].decode(),
            history: try js[.history]?.decode() ?? []
        )
    }
}
#if TESTABLE
extension Tile: Equatable {}
#endif
