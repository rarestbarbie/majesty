import Color
import JavaScriptInterop
import JavaScriptKit

struct ResourceDescription {
    let color: Color
    let emoji: Character
    let local: Bool
}
extension ResourceDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case color
        case emoji
        case local
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode(),
            emoji: try js[.emoji].decode(),
            local: try js[.local]?.decode() ?? false,
        )
    }
}
