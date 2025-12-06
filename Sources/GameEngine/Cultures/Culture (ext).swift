import Color
import GameIDs
import GameRules
import JavaScriptKit
import JavaScriptInterop

extension Culture {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case name
        case type
        case color
    }
}
extension Culture: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.type] = self.type
        js[.color] = self.color
    }
}
extension Culture: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name].decode(),
            type: try js[.type].decode(),
            color: try js[.color].decode()
        )
    }
}
