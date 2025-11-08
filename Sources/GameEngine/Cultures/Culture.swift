import Color
import JavaScriptKit
import JavaScriptInterop

struct Culture: Identifiable {
    let id: String
    let color: Color
}

extension Culture {
    enum ObjectKey: JSString, Sendable {
        case id
        case color
    }
}

extension Culture: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.color] = self.color
    }
}

extension Culture: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            color: try js[.color].decode()
        )
    }
}
