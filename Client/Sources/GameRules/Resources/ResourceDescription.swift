import Color
import JavaScriptInterop
import JavaScriptKit

struct ResourceDescription {
    let color: Color
    let emoji: Character
}
extension ResourceDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case color
        case emoji
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode(),
            emoji: try js[.emoji].decode(),
        )
    }
}
