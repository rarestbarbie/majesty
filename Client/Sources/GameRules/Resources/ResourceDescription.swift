import Color
import JavaScriptInterop
import JavaScriptKit

struct ResourceDescription {
    let color: Color
    let emoji: Character
    let local: Bool
    let hours: Int64?
}
extension ResourceDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case color
        case emoji
        case local
        case hours
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode(),
            emoji: try js[.emoji].decode(),
            local: try js[.local]?.decode() ?? false,
            hours: try js[.hours]?.decode()
        )
    }
}
