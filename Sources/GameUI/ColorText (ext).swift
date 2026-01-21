import ColorText
import JavaScriptInterop

extension ColorText: ConvertibleToJSValue {
    @inlinable public var jsValue: JSValue {
        .string(JSString.init(self.html))
    }
}
