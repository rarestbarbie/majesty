import JavaScriptInterop

extension GeologicalDescription.Bonuses {
    enum ObjectKey {
        case underscore
        case resource(Symbol)
    }
}
extension GeologicalDescription.Bonuses.ObjectKey: RawRepresentable {
    init(rawValue: JSString) {
        self = rawValue == "_"
            ? .underscore
            : .resource(Symbol.init(rawValue: rawValue))
    }

    var rawValue: JSString {
        switch self {
        case .underscore: "_"
        case .resource(let symbol): symbol.rawValue
        }
    }
}
