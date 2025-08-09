import JavaScriptInterop
import JavaScriptKit

@frozen public struct TerrainType: RawRepresentable, Equatable, Hashable, Sendable,
    ComparableByRawValue,
    ConvertibleToJSValue,
    LoadableFromJSValue {

    public let rawValue: Int16
    @inlinable public init(rawValue: Int16) { self.rawValue = rawValue }
}
