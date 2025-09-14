import Color
import JavaScriptInterop
import JavaScriptKit

struct GeologicalDescription {
    let name: String
    let base: OrderedTable<Int64>
    let bonus: SymbolTable<OrderedTable<GeologicalSpawnWeight>>
    let color: Color
}
extension GeologicalDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case name
        case base = "base_resources"
        case bonus = "bonus_resources"
        case color
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            name: try js[.name].decode(),
            base: try js[.base].decode(),
            bonus: try js[.bonus].decode(),
            color: try js[.color].decode()
        )
    }
}
