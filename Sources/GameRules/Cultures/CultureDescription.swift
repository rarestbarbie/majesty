import Color
import JavaScriptInterop
import JavaScriptKit

struct CultureDescription {
    let diet: SymbolTable<Int64>
    let meat: SymbolTable<Int64>
}
extension CultureDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case diet
        case meat
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            diet: try js[.diet]?.decode() ?? [:],
            meat: try js[.meat]?.decode() ?? [:]
        )
    }
}
