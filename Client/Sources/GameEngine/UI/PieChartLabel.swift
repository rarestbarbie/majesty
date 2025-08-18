import Color
import JavaScriptKit
import JavaScriptInterop

struct PieChartLabel {
    let color: Color
    let name: String
}
extension PieChartLabel: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case color
        case name
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.color] = self.color
        js[.name] = self.name
    }
}
