import JavaScriptInterop

extension Dictionary
    where Key: ConvertibleToJSValue & LoadableFromJSValue & Sendable & Comparable,
    Value: ConvertibleToJSValue & LoadableFromJSValue {
    var sorted: Sorted { .init(dictionary: self) }
}
