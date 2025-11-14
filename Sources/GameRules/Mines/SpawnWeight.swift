import D
import JavaScriptInterop
import JavaScriptKit

@frozen public struct SpawnWeight: Hashable, Equatable {
    public let rate: Exact
    public let size: Int64

    @inlinable init(rate: Exact, size: Int64) {
        self.rate = rate
        self.size = size
    }
}
extension SpawnWeight: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case rate
        case size
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            rate: try js[.rate].decode(),
            size: try js[.size].decode()
        )
    }
}
