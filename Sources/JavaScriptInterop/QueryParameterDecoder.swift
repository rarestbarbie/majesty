import JavaScriptBackend

@frozen public struct QueryParameterDecoder<QueryKey>: ~Copyable
    where QueryKey: RawRepresentable<JSString> {
    @usableFromInline let get: ((any ConvertibleToJSValue...) -> JSValue)
    @inlinable init(get: @escaping (any ConvertibleToJSValue...) -> JSValue) {
        self.get = get
    }
}
extension QueryParameterDecoder {
    #if WebAssembly
    @inlinable init(wrapping object: JSObject) {
        guard let get: (any ConvertibleToJSValue...) -> JSValue = object.get else {
            fatalError("member 'URLSearchParams.get' is not defined!")
        }
        self.init(get: get)
    }
    #endif
}
extension QueryParameterDecoder {
    @inlinable func get(_ key: JSString) -> JSString? {
        let value: JSValue = self.get(key)
        switch value {
        case .null:
            return nil
        case .string(let value):
            return value
        default:
            fatalError("URLSearchParams.get() returned an unexpected value '\(value)'")
        }
    }

    @inlinable public subscript(_ key: QueryKey) -> Field {
        let key: JSString = key.rawValue
        return .init(id: key, value: self.get(key))
    }

    @inlinable public subscript(_ key: QueryKey) -> Field? {
        let key: JSString = key.rawValue
        if  let value: JSString = self.get(key) {
            return .init(id: key, value: value)
        } else {
            return nil
        }
    }
}
