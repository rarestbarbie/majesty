import JavaScriptInterop
import JavaScriptKit

struct PopDescription {
    let l: SymbolTable<Int64>
    let e: SymbolTable<Int64>
    let x: SymbolTable<Int64>
    let output: SymbolTable<Int64>
}
extension PopDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case l
        case e
        case x
        case output
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            l: try js[.l]?.decode() ?? [:],
            e: try js[.e]?.decode() ?? [:],
            x: try js[.x]?.decode() ?? [:],
            output: try js[.output]?.decode() ?? [:]
        )
    }
}
