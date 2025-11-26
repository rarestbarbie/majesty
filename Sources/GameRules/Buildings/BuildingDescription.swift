import JavaScriptInterop
import JavaScriptKit

struct BuildingDescription {
    let maintenance: SymbolTable<Int64>
    let development: SymbolTable<Int64>
    let output: SymbolTable<Int64>
    let terrain: [Symbol]
    let required: Bool
}
extension BuildingDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case maintenance
        case development
        case output
        case terrain
        case required
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            maintenance: try js[.maintenance].decode(),
            development: try js[.development].decode(),
            output: try js[.output].decode(),
            terrain: try js[.terrain]?.decode() ?? [],
            required: try js[.required]?.decode() ?? false
        )
    }
}
