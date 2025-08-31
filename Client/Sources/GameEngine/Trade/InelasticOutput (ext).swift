import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension InelasticOutput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
    }
}
extension InelasticOutput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
    }
}
extension InelasticOutput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
        )
    }
}
