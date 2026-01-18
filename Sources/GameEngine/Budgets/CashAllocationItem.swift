import JavaScriptInterop

@frozen public enum CashAllocationItem: Unicode.Scalar, CaseIterable {
    case buybacks = "b"
    case dividend = "d"
    case x = "x"
    case e = "e"
    case l = "l"
    case wages = "w"
    case salaries = "c"
}
extension CashAllocationItem: ConvertibleToJSValue, LoadableFromJSValue {
}
