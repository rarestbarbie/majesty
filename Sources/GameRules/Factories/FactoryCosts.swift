import JavaScriptInterop
import JavaScriptKit

struct FactoryCosts {
    let corporate: SymbolTable<SymbolTable<Int64>>
    let expansion: SymbolTable<SymbolTable<Int64>>
    let sharesInitial: Int64
    let sharesPerLevel: Int64
}
extension FactoryCosts: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case corporate
        case expansion
        case shares_initial
        case shares_per_level
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            corporate: try js[.corporate].decode(),
            expansion: try js[.expansion].decode(),
            sharesInitial: try js[.shares_initial].decode(),
            sharesPerLevel: try js[.shares_per_level].decode()
        )
    }
}
