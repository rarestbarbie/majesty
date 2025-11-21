import Color
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct Culture: Identifiable {
    let id: String
    /// Should really be `CultureType`, but that would be hard to bootstrap.
    let type: Symbol?
    let color: Color
}

extension Culture {
    enum ObjectKey: JSString, Sendable {
        case id
        case type
        case color
    }
}

extension Culture: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.type] = self.type
        js[.color] = self.color
    }
}

extension Culture: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            type: try js[.type]?.decode(),
            color: try js[.color].decode()
        )
    }
}
