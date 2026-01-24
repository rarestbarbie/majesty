import Color
import JavaScriptInterop

struct BuildingDescription {
    let color: Color
    let operations: SymbolTable<Int64>
    let maintenance: SymbolTable<Int64>?
    let development: SymbolTable<Int64>?
    let output: SymbolTable<Int64>
    let terrain: [Symbol]
    let required: Bool
}
extension BuildingDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case color
        case operations
        case maintenance
        case development
        case output
        case terrain
        case required
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            color: try js[.color].decode(),
            operations: try js[.operations].decode(),
            maintenance: try js[.maintenance]?.decode(),
            development: try js[.development]?.decode(),
            output: try js[.output].decode(),
            terrain: try js[.terrain]?.decode() ?? [],
            required: try js[.required]?.decode() ?? false
        )
    }
}
