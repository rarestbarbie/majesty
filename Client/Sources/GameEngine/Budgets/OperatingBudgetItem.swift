import JavaScriptInterop
import JavaScriptKit

@frozen public enum OperatingBudgetItem: Unicode.Scalar, CaseIterable {
    case buybacks = "B"
    case dividend = "D"
    case labor = "L"
    case inputs = "I"
    case maintenance = "M"
    case capex = "X"
}
extension OperatingBudgetItem: ConvertibleToJSValue, LoadableFromJSValue {
}
