import JavaScriptKit
import JavaScriptInterop

extension Mine {
    struct Dimensions {
        var size: Int64
    }
}
extension Mine.Dimensions {
    init() {
        self.init(
            size: 0
        )
    }
}
extension Mine.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case size = "size"
    }
}
extension Mine.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.size] = self.size
    }
}
extension Mine.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            size: try js[.size].decode()
        )
    }
}

#if TESTABLE
extension Mine.Dimensions: Equatable, Hashable {}
#endif
