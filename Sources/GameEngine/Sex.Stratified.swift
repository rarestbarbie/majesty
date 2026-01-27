import GameIDs
import JavaScriptInterop

extension Sex {
    struct Stratified<T> {
        var f: T
        var x: T
        var m: T
    }
}
extension Sex.Stratified {
    func map<U>(_ transform: (T) throws -> U) rethrows -> Sex.Stratified<U> {
        .init(
            f: try transform(self.f),
            x: try transform(self.x),
            m: try transform(self.m)
        )
    }

    subscript(sex: Sex) -> T {
        _read {
            switch sex {
            case .F: yield self.f
            case .X: yield self.x
            case .M: yield self.m
            }
        }
        _modify {
            switch sex {
            case .F: yield &self.f
            case .X: yield &self.x
            case .M: yield &self.m
            }
        }
    }
}
extension Sex.Stratified: Sendable where T: Sendable {}
extension Sex.Stratified: Equatable where T: Equatable {}
extension Sex.Stratified: AdditiveArithmetic where T: AdditiveArithmetic {
    static var zero: Self { .init(f: .zero, x: .zero, m: .zero) }

    static func + (a: Self, b: Self) -> Self {
        .init(
            f: a.f + b.f,
            x: a.x + b.x,
            m: a.m + b.m
        )
    }
    static func - (a: Self, b: Self) -> Self {
        .init(
            f: a.f - b.f,
            x: a.x - b.x,
            m: a.m - b.m
        )
    }
}
extension Sex.Stratified where T: AdditiveArithmetic {
    var all: T {
        self.f + self.x + self.m
    }
}
extension Sex.Stratified {
    enum ObjectKey: JSString, Sendable {
        case f = "f"
        case x = "x"
        case m = "m"
    }
}
extension Sex.Stratified: JavaScriptEncodable, ConvertibleToJSValue where T: ConvertibleToJSValue {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.f] = self.f
        js[.x] = self.x
        js[.m] = self.m
    }
}
extension Sex.Stratified: JavaScriptDecodable, LoadableFromJSValue, ConstructibleFromJSValue
    where T: LoadableFromJSValue {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            f: try js[.f].decode(),
            x: try js[.x].decode(),
            m: try js[.m].decode()
        )
    }
}
