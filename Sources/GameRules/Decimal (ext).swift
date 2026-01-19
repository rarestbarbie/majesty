import D
import JavaScriptInterop

extension Decimal: LoadableFromJSString, ConvertibleToJSString,
    @retroactive ConstructibleFromJSValue,
    @retroactive ConvertibleToJSValue {
}
