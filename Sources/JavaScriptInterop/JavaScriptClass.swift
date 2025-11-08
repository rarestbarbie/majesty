import JavaScriptKit

@frozen @usableFromInline enum JavaScriptClass: JSString, Sendable {
    case Object
    case Array
}
extension JavaScriptClass {
    @inlinable var constructor: JSObject {
        JSObject.global[self.rawValue].function!
    }
}
extension JavaScriptClass: CustomStringConvertible {
    @inlinable var description: String { self.rawValue.description }
}
