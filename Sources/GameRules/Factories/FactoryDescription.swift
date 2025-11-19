import JavaScriptInterop
import JavaScriptKit

struct FactoryDescription {
    let materials: SymbolTable<Int64>
    let corporate: SymbolTable<Int64>?
    let expansion: SymbolTable<Int64>?
    let output: SymbolTable<Int64>
    let workers: SymbolTable<Int64>
    let terrain: [Symbol]
}
extension FactoryDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case materials
        case corporate
        case expansion
        case output
        case workers
        case terrain
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            materials: try js[.materials]?.decode() ?? [:],
            corporate: try js[.corporate]?.decode(),
            expansion: try js[.expansion]?.decode(),
            output: try js[.output].decode(),
            workers: try js[.workers].decode(),
            terrain: try js[.terrain]?.decode() ?? []
        )
    }
}
