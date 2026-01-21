import JavaScriptBackend

extension FixedWidthInteger where Self: SignedInteger & LoadableFromJSValue {
    @inlinable public static func load(from value: JSValue) throws -> Self {
        #if WebAssembly
        // JavaScriptKit does not use enough @inlinable
        if  case .number(let number) = value,
            let number: Self = .init(exactly: number) {
            return number
        } else if
            case .bigInt(let number) = value,
            let number: Self = .init(exactly: number.int64Value) {
            return number
        }
        #else
        if  let value: Self = .construct(from: value) {
            return value
        }
        #endif
        throw JavaScriptTypecastError<Self>.diagnose(value)
    }
}
extension FixedWidthInteger where Self: UnsignedInteger & LoadableFromJSValue {
    @inlinable public static func load(from value: JSValue) throws -> Self {
        #if WebAssembly
        if  case .number(let number) = value,
            let number: Self = .init(exactly: number) {
            return number
        } else if
            case .bigInt(let number) = value,
            let number: Self = .init(exactly: number.uInt64Value) {
            return number
        }
        #else
        if  let value: Self = .construct(from: value) {
            return value
        }
        #endif
        throw JavaScriptTypecastError<Self>.diagnose(value)
    }
}
