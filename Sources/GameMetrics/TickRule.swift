import ColorText
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TickRule {
    let id: Int
    let value: Double
    let label: String
    let style: ColorText.Style?
}
extension TickRule: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case value = "y"
        case label = "l"
        case style = "s"
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.value] = self.value
        js[.label] = self.label
        js[.style] = self.style?.id
    }
}
