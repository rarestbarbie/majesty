import JavaScriptInterop
import JavaScriptKit

@frozen public struct Symbol: Hashable {
    public let name: String

    @inlinable init(name: String) {
        self.name = name
    }
}
extension Symbol: Comparable {
    @inlinable public static func < (a: Symbol, b: Symbol) -> Bool { a.name < b.name }
}
extension Symbol: ExpressibleByStringLiteral {
    @inlinable public init(stringLiteral: String) {
        self.init(name: stringLiteral)
    }
}
extension Symbol: RawRepresentable, LoadableFromJSValue, ConvertibleToJSValue {
    @inlinable public init(rawValue: JSString) { self.init(name: rawValue.description) }
    @inlinable public var rawValue: JSString { .init(self.name) }
}
