import D
import JavaScriptInterop
import JavaScriptKit

@frozen public struct Exact: Sendable {
    public let value: Decimal

    @inlinable public init(value: Decimal) {
        self.value = value
    }
}
extension Exact: Equatable {
    @inlinable public static func == (a: Self, b: Self) -> Bool {
        (a.value.units, a.value.power) == (b.value.units, b.value.power)
    }
}
extension Exact: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        self.value.units.hash(into: &hasher)
        self.value.power.hash(into: &hasher)
    }
}
extension Exact: CustomStringConvertible {
    @inlinable public var description: String { "\(self.value)" }
}
extension Exact: LosslessStringConvertible {
    @inlinable public init?(
        _ string: consuming some StringProtocol & RangeReplaceableCollection) {
        guard let value: Decimal = .init(string) else {
            return nil
        }
        self.init(value: value)
    }
}
extension Exact: ConvertibleToJSString, LoadableFromJSString {}
