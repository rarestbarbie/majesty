import ColorReference
import JavaScriptInterop

@frozen public struct TickRule {
    let id: Int
    let value: Double
    let label: ColorReference?
    let grid: Bool
    let text: String
}
extension TickRule: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case value = "y"
        case label
        case grid
        case text
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.value] = self.value
        js[.label] = self.label
        js[.grid] = self.grid ? true : nil
        js[.text] = self.text
    }
}
