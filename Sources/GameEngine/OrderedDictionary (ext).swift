import GameState
import JavaScriptInterop
import OrderedCollections

extension OrderedDictionary where Key: ConvertibleToJSValue & LoadableFromJSValue & Sendable,
    Value: ConvertibleToJSValue & LoadableFromJSValue {
    var items: Items { .init(dictionary: self) }
}
extension OrderedDictionary: LoadableFromJSArray, LoadableFromJSValue,
    @retroactive ConstructibleFromJSValue
    where Value: LoadableFromJSValue, Value: Identifiable, Key == Value.ID {
    @inlinable public static func load(
        from js: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Self {
        let count: Int = try js[.length].decode()
        var index: Self = .init(minimumCapacity: count)
        for i: Int in 0 ..< count {
            let object: Value = try js[i].decode()
            try {
                if case _? = $0 {
                    throw OrderedDictionaryCollisionError<Int>.init(id: i)
                } else {
                    $0 = object
                }
            } (&index[object.id])
        }
        return index
    }
}
extension OrderedDictionary: ConvertibleToJSArray,
    @retroactive ConvertibleToJSValue
    where Value: ConvertibleToJSValue {
    @inlinable public func encode(to js: inout JavaScriptEncoder<JavaScriptArrayKey>) {
        js[.length] = self.count
        for (i, value): (Int, Value) in self.values.enumerated() {
            js[i] = value
        }
    }
}
