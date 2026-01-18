import Color
import ColorReference
import JavaScriptInterop
import JavaScriptKit
import OrderedCollections

struct GeologicalDescription {
    let title: String
    let base: OrderedDictionary<Symbol, Int64>
    let bonus: SymbolTable<Bonuses>
    let color: Color
}
extension GeologicalDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case title = "name"
        case base = "base_resources"
        case bonus = "bonus_resources"
        case color
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let base: OrderedTable<Int64> = try js[.base].decode()
        self.init(
            title: try js[.title].decode(),
            base: base.index,
            bonus: try js[.bonus].decode(),
            color: try js[.color].decode()
        )
    }
}
