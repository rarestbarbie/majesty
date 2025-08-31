import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension InelasticInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
    }
}
extension InelasticInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
    }
}
extension InelasticInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
        )
    }
}
