import JavaScriptInterop

extension PopAttributesDescription {
    enum Predicate {
        case occupation(Symbol)
        case stratum(Symbol)
        case biology(Symbol)
    }
}
extension PopAttributesDescription.Predicate: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case occupation
        case stratum
        case biology
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        if  let symbol: Symbol = try js[.occupation]?.decode() {
            self = .occupation(symbol)
        } else if
            let symbol: Symbol = try js[.biology]?.decode() {
            self = .biology(symbol)
        } else {
            let symbol: Symbol = try js[.stratum].decode()
            self = .stratum(symbol)
        }
    }
}

