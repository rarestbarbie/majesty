import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

extension OrderedDictionary {
    struct Items where Key: ConvertibleToJSValue & LoadableFromJSValue & Sendable,
        Value: ConvertibleToJSValue & LoadableFromJSValue {
        let dictionary: OrderedDictionary<Key, Value>
    }
}
extension OrderedDictionary.Items: RandomAccessCollection {
    var startIndex: Int { self.dictionary.elements.startIndex }
    var endIndex: Int { self.dictionary.elements.endIndex }
    subscript(position: Int) -> OrderedDictionary.Item {
        let (key, value) = self.dictionary.elements[position]
        return .init(key: key, value: value)
    }
}
extension OrderedDictionary.Items: ConvertibleToJSArray {}
extension OrderedDictionary.Items: LoadableFromJSArray {
    @inlinable public static func load(
        from js: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Self {
        let count: Int = try js[.length].decode()
        var index: OrderedDictionary<Key, Value> = .init(minimumCapacity: count)
        for i: Int in 0 ..< count {
            let item: OrderedDictionary<Key, Value>.Item = try js[i].decode()
            try {
                if case _? = $0 {
                    throw OrderedDictionaryCollisionError<Key>.init(id: item.key)
                } else {
                    $0 = item.value
                }
            } (&index[item.key])
        }
        return .init(dictionary: index)
    }
}
