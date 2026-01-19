import DequeModule
import JavaScriptInterop

extension Deque: LoadableFromJSArray, LoadableFromJSValue,
    @retroactive ConstructibleFromJSValue
    where Element: LoadableFromJSValue {
    public static func load(
        from js: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Self {
        let count: Int = try js[.length].decode()
        var deque: Self = .init(minimumCapacity: count)
        for i: Int in 0 ..< count {
            deque.append(try js[i].decode())
        }
        return deque
    }
}
extension Deque: ConvertibleToJSArray,
    @retroactive ConvertibleToJSValue
    where Element: ConvertibleToJSValue {
    public func encode(to js: inout JavaScriptEncoder<JavaScriptArrayKey>) {
        js[.length] = self.count
        for (i, element): (Int, Element) in self.enumerated() {
            js[i] = element
        }
    }
}
