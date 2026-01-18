import JavaScriptInterop

extension Dictionary {
    /// A persistence abstraction to deterministically encode and decode a dictionary in a
    /// sorted order based on its keys. It is expensive to encode and decode, but enables using
    /// a lighter-weight standard library alternative to ``OrderedDictionary`` at runtime.
    struct Sorted
        where Key: ConvertibleToJSValue & LoadableFromJSValue & Sendable & Comparable,
        Value: ConvertibleToJSValue & LoadableFromJSValue {
        let dictionary: [Key: Value]
    }
}
extension Dictionary.Sorted: Sendable where Key: Sendable, Value: Sendable {}
extension Dictionary.Sorted {
    @frozen public enum ObjectKey: JSString, Sendable {
        case k = "k"
        case v = "v"
    }
}
extension Dictionary.Sorted: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        let items: [(key: Key, value: Value)] = self.dictionary.sorted { $0.key < $1.key }
        js[.k] = items.lazy.map(\.key)
        js[.v] = items.lazy.map(\.value)
    }
}
extension Dictionary.Sorted: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let keys: [Key] = try js[.k].decode()
        let values: [Value] = try js[.v].decode()
        var dictionary: [Key: Value] = .init(minimumCapacity: keys.count)
        for (key, value): (Key, Value) in zip(keys, values) {
            dictionary[key] = value
        }
        self.init(dictionary: dictionary)
    }
}
