import JavaScriptInterop
import JavaScriptKit

struct TechnologyDescription {
    let starter: Bool
    let effects: EffectsDescription
    let summary: String
}
extension TechnologyDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case starter
        case effects
        case summary
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            starter: try js[.starter].decode(),
            effects: try js[.effects].decode(),
            summary: try js[.summary]?.decode() ?? "",
        )
    }
}
