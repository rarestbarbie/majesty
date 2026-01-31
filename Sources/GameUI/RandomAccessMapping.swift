public protocol RandomAccessMapping<Key, Value> {
    associatedtype Values: Collection<Value>
    associatedtype Value
    associatedtype Key

    subscript(key: Key) -> Value? { get }
    var values: Values { get }
}
