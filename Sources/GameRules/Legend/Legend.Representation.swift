import Color
import JavaScriptInterop

extension Legend {
    @frozen public struct Representation {
        public let color: Color
    }
}
extension Legend.Representation {
    @frozen public enum ObjectKey: JSString, Sendable {
        case color
    }
}
extension Legend.Representation: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.color] = self.color
    }
}
extension Legend.Representation: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode()
        )
    }
}
