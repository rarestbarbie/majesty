import JavaScriptKit
import JavaScriptInterop

extension Dictionary: RandomAccessMapping {}
extension Dictionary
    where Key: ConvertibleToJSValue & LoadableFromJSValue & Sendable & Comparable,
    Value: ConvertibleToJSValue & LoadableFromJSValue {
    var sorted: Sorted { .init(dictionary: self) }
}
