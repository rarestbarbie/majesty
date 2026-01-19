import JavaScriptInterop
import VectorCharts

extension PieChart: ConvertibleToJSArray, ConvertibleToJSValue
    where Key: ConvertibleToJSValue, Value: ConvertibleToJSValue {
}
