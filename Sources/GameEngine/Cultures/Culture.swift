import Color
import GameIDs
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct Culture: Identifiable {
    let id: CultureID
    let name: String
    let type: CultureType
    let color: Color
}

extension Culture {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case type
        case color
    }
}

extension Culture: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.type] = self.type
        js[.color] = self.color
    }
}

extension Culture: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name].decode(),
            type: try js[.type].decode(),
            color: try js[.color].decode()
        )
    }
}
