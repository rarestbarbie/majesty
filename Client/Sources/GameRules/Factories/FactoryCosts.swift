import JavaScriptInterop
import JavaScriptKit

struct FactoryCosts {
    let construction: SymbolTable<SymbolTable<Int64>>
    let sharesInitial: Int64
    let sharesPerLevel: Int64
}
extension FactoryCosts: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case construction
        case shares_initial
        case shares_per_level
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            construction: try js[.construction].decode(),
            sharesInitial: try js[.shares_initial].decode(),
            sharesPerLevel: try js[.shares_per_level].decode()
        )
    }
}
