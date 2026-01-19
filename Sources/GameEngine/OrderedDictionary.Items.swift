import JavaScriptInterop
import OrderedCollections

extension OrderedDictionary {
    struct Items where Key: ConvertibleToJSValue & LoadableFromJSValue & Sendable,
        Value: ConvertibleToJSValue & LoadableFromJSValue {
        let dictionary: OrderedDictionary<Key, Value>
    }
}
extension OrderedDictionary.Items: Sendable where Key: Sendable, Value: Sendable {}
extension OrderedDictionary.Items {
    @frozen public enum ObjectKey: JSString, Sendable {
        case k = "k"
        case v = "v"
    }
}
extension OrderedDictionary.Items: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.k] = self.dictionary.keys.elements
        js[.v] = self.dictionary.values.elements
    }
}
extension OrderedDictionary.Items: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let keys: [Key] = try js[.k].decode()
        let values: [Value] = try js[.v].decode()
        var dictionary: OrderedDictionary<Key, Value> = .init(minimumCapacity: keys.count)
        for (key, value): (Key, Value) in zip(keys, values) {
            dictionary[key] = value
        }
        self.init(dictionary: dictionary)
    }
}
