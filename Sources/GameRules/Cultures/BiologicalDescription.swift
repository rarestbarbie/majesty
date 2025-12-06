import Color
import JavaScriptInterop
import JavaScriptKit

struct BiologicalDescription {
}
extension BiologicalDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case _empty
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
        )
    }
}
