import HexGrids
import JavaScriptInterop

extension HexRotation: RawRepresentable {
    @inlinable public init?(rawValue: Bool) {
        self = rawValue ? .ccw : .cw
    }

    @inlinable public var rawValue: Bool {
        switch self {
        case .cw: false
        case .ccw: true
        }
    }
}
extension HexRotation: LoadableFromJSValue, ConvertibleToJSValue {
}
