import OrderedCollections
import JavaScriptInterop

extension OrderedSet: ConvertibleToJSArray,
    @retroactive ConvertibleToJSValue where Element: ConvertibleToJSValue {}
extension OrderedSet: LoadableFromJSArray, LoadableFromJSValue,
    @retroactive ConstructibleFromJSValue where Element: LoadableFromJSValue {
    // unfortunately, ``OrderedSet`` does not conform to ``RangeReplaceableCollection``, so we
    // have to reimplement this method rather than relying on the default implementation
    @inlinable public static func load(
        from js: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Self {
        let count: Int = try js[.length].decode()
        var set: Self = .init(minimumCapacity: count)
        for i: Int in 0 ..< count {
            set.append(try js[i].decode())
        }
        return set
    }
}
