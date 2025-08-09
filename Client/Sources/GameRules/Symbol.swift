import JavaScriptInterop
import JavaScriptKit

@frozen @usableFromInline struct Symbol: Hashable {
    @usableFromInline let name: String

    @inlinable init(name: String) {
        self.name = name
    }
}
extension Symbol: Comparable {
    @inlinable static func < (a: Symbol, b: Symbol) -> Bool { a.name < b.name }
}
extension Symbol: ExpressibleByStringLiteral {
    @inlinable init(stringLiteral: String) {
        self.init(name: stringLiteral)
    }
}
extension Symbol: RawRepresentable {
    @inlinable init(rawValue: JSString) { self.init(name: rawValue.description) }
    @inlinable var rawValue: JSString { .init(self.name) }
}
