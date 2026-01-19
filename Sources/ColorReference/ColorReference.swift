import Color
import JavaScriptInterop

@frozen public enum ColorReference {
    case color(Color)
    case style(String)
}
extension ColorReference: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case color
        case style
    }

    @inlinable public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        switch self {
        case .color(let color): js[.color] = color
        case .style(let style): js[.style] = style
        }
    }
}
