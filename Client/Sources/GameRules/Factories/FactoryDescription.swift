import JavaScriptInterop
import JavaScriptKit

struct FactoryDescription {
    let inputs: SymbolTable<Int64>
    let output: SymbolTable<Int64>
    let workers: SymbolTable<Int64>
}
extension FactoryDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case inputs
        case output
        case workers
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            inputs: try js[.inputs].decode(),
            output: try js[.output].decode(),
            workers: try js[.workers].decode()
        )
    }
}
