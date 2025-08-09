public protocol Condition<Value> {
    associatedtype Value
    static func ~ (value: Value, self: Self) -> Bool
    var predicate: Value { get }
}
