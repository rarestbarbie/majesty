import Color
import JavaScriptInterop

struct PopAttributesDescription {
    let `where`: Predicate?
    let base: (
        l: SymbolTable<Int64>?,
        e: SymbolTable<Int64>?,
        x: SymbolTable<Int64>?,
        output: SymbolTable<Int64>?,
    )
    let plus: (
        l: SymbolTable<Int64>?,
        e: SymbolTable<Int64>?,
        x: SymbolTable<Int64>?,
        output: SymbolTable<Int64>?,
    )
}
extension PopAttributesDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case `where`
        case l_base = "l"
        case e_base = "e"
        case x_base = "x"
        case output_base = "output"

        case l_plus = "+l"
        case e_plus = "+e"
        case x_plus = "+x"
        case output_plus = "+output"
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            where: try js[.where]?.decode(),
            base: (
                l: try js[.l_base]?.decode(),
                e: try js[.e_base]?.decode(),
                x: try js[.x_base]?.decode(),
                output: try js[.output_base]?.decode(),
            ),
            plus: (
                l: try js[.l_plus]?.decode(),
                e: try js[.e_plus]?.decode(),
                x: try js[.x_plus]?.decode(),
                output: try js[.output_plus]?.decode(),
            )
        )
    }
}
