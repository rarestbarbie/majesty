import Color
import JavaScriptInterop

struct PopAttributesDescription {
    let `where`: Predicate?
    let l: SymbolTable<Int64>?
    let e: SymbolTable<Int64>?
    let x: SymbolTable<Int64>?
    let output: SymbolTable<Int64>?
}
extension PopAttributesDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case `where`
        case l
        case e
        case x
        case output
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            where: try js[.where]?.decode(),
            l: try js[.l]?.decode(),
            e: try js[.e]?.decode(),
            x: try js[.x]?.decode(),
            output: try js[.output]?.decode(),
        )
    }
}
