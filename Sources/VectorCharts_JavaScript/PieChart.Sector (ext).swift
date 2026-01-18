import JavaScriptInterop
import VectorCharts

extension PieChart.Sector: JavaScriptEncodable, ConvertibleToJSValue
    where Key: ConvertibleToJSValue, Value: ConvertibleToJSValue {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case d
        case share
        case value
    }

    @inlinable public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.d] = self.slice?.d
        js[.share] = self.share
        js[.value] = self.value
    }
}
