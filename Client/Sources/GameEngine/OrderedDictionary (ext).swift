import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

extension OrderedDictionary {
    /// Update each value in place, removing any for which `yield` returns false.
    /// This is more efficient than calling `removeValue(forKey:)` repeatedly, and has best
    /// case performance when all values are retained.
    mutating func update(with yield: (_ value: inout Value) throws -> Bool) rethrows {
        let remove: [Int] = try self.values.indices.reduce(into: []) {
            if try !yield(&self.values[$1]) {
                $0.append($1)
            }
        }
        if  remove.isEmpty {
            return
        }
        // rebuild the dictionary, taking advantage of the fact that `remove` is sorted
        var new: Self = .init(minimumCapacity: self.count - remove.count)
        var remaining: [Int].Iterator = remove.makeIterator()
        var next: Int? = remaining.next()
        for i: Int in self.values.indices {
            if case i? = next {
                next = remaining.next()
            } else {
                new[self.keys[i]] = self.values[i]
            }
        }
        self = new
    }
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
