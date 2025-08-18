import Color
import JavaScriptKit
import JavaScriptInterop

public struct Culture: Identifiable {
    public let id: String
    public let color: Color
}

extension Culture {
    public enum ObjectKey: JSString, Sendable {
        case id
        case color
    }
}

extension Culture: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.color] = self.color
    }
}

extension Culture: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            color: try js[.color].decode()
        )
    }
}
