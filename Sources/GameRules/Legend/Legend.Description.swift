import JavaScriptInterop

extension Legend {
    struct Description {
        let occupation: SymbolTable<Representation>
        let gender: SymbolTable<Representation>
    }
}
extension Legend.Description {
    enum ObjectKey: JSString, Sendable {
        case occupation
        case gender
    }
}
extension Legend.Description: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            occupation: try js[.occupation].decode(),
            gender: try js[.gender].decode()
        )
    }
}
