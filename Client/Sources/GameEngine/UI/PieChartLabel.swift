import Color
import JavaScriptKit
import JavaScriptInterop

struct PieChartLabel {
    let color: Color?
    let style: String?
    let name: String

    init(color: Color? = nil, style: String? = nil, name: String) {
        self.color = color
        self.style = style
        self.name = name
    }
}
extension PieChartLabel: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case color
        case style
        case name
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.color] = self.color
        js[.style] = self.style
        js[.name] = self.name
    }
}
