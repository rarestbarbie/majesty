import JavaScriptInterop

extension Tile {
    struct Aggregate {
        let gdp: Int64
        let gnp: Double
    }
}
extension Tile.Aggregate {
    enum ObjectKey: JSString, Sendable {
        case gdp
        case gnp
    }
}
extension Tile.Aggregate: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.gdp] = self.gdp
        js[.gnp] = self.gnp
    }
}
extension Tile.Aggregate: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            gdp: try js[.gdp].decode(),
            gnp: try js[.gnp].decode()
        )
    }
}
#if TESTABLE
extension Tile.Aggregate: Equatable {}
#endif
