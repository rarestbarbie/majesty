import Color
import GameIDs
import GameRules
import JavaScriptInterop

@frozen public struct CultureSeed: Identifiable {
    public let id: CultureID?
    public let name: Symbol
    public let type: Symbol?
    public let color: Color
}
extension CultureSeed {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case name
        case type
        case color
    }
}
extension CultureSeed: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.type] = self.type
        js[.color] = self.color
    }
}
extension CultureSeed: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id]?.decode(),
            name: try js[.name].decode(),
            type: try js[.type]?.decode(),
            color: try js[.color].decode()
        )
    }
}
