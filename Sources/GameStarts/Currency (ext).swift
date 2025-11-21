import GameIDs
import GameRules
import JavaScriptInterop
import JavaScriptKit

extension Currency {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case name
        case long
    }
}
extension Currency: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.long] = self.long
    }
}
extension Currency: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name].decode(),
            long: try js[.long].decode()
        )
    }
}
