import JavaScriptInterop
import JavaScriptKit

struct FactoryDescription {
    let inputs: SymbolTable<Int64>
    let office: SymbolTable<Int64>
    let output: SymbolTable<Int64>
    let workers: SymbolTable<Int64>
    let terrain: [Symbol]
}
extension FactoryDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case inputs
        case office
        case output
        case workers
        case terrain
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            inputs: try js[.inputs]?.decode() ?? [:],
            office: try js[.office]?.decode() ?? [:],
            output: try js[.output].decode(),
            workers: try js[.workers].decode(),
            terrain: try js[.terrain]?.decode() ?? []
        )
    }
}
