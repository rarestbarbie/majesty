import JavaScriptInterop

extension Tile {
    struct Aggregate {
        let gdp: Int64
    }
}
extension Tile.Aggregate {
    enum ObjectKey: JSString, Sendable {
        case gdp
    }
}
extension Tile.Aggregate: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.gdp] = self.gdp
    }
}
extension Tile.Aggregate: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            gdp: try js[.gdp].decode(),
        )
    }
}
#if TESTABLE
extension Tile.Aggregate: Equatable, Hashable {}
#endif
