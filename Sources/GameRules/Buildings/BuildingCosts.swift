import JavaScriptInterop
import JavaScriptKit

struct BuildingCosts {
    let maintenance: SymbolTable<SymbolTable<Int64>>
    let development: SymbolTable<SymbolTable<Int64>>
    let sharesInitial: Int64
    let sharesPerLevel: Int64
}
extension BuildingCosts: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case maintenance
        case development
        case shares_initial
        case shares_per_level
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            maintenance: try js[.maintenance].decode(),
            development: try js[.development].decode(),
            sharesInitial: try js[.shares_initial].decode(),
            sharesPerLevel: try js[.shares_per_level].decode()
        )
    }
}
