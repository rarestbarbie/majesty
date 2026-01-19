import JavaScriptInterop
import OrderedCollections

extension OrderedDictionary {
    struct Item where Key: ConvertibleToJSValue & LoadableFromJSValue,
        Value: ConvertibleToJSValue & LoadableFromJSValue {
        let key: Key
        let value: Value
    }
}
extension OrderedDictionary.Item {
    enum ObjectKey: JSString, Sendable {
        case key = "k"
        case value = "v"
    }
}
extension OrderedDictionary.Item: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.key] = self.key
        js[.value] = self.value
    }
}
extension OrderedDictionary.Item: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(key: try js[.key].decode(), value: try js[.value].decode())
    }
}
