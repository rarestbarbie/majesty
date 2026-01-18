import Color
import JavaScriptInterop

struct EcologicalDescription {
    let color: Color
}
extension EcologicalDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case color
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode()
        )
    }
}
