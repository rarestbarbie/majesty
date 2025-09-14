import D
import JavaScriptInterop
import JavaScriptKit

extension Decimal: LoadableFromJSString, ConvertibleToJSString,
    @retroactive ConstructibleFromJSValue,
    @retroactive ConvertibleToJSValue {
}
