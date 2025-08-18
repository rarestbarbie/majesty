@frozen public struct ConditionAtLeast<Value>: Condition where Value: Comparable {
    public let predicate: Value

    @inlinable init(predicate: Value) {
        self.predicate = predicate
    }

    @inlinable public static func ~ (value: Value, self: Self) -> Bool {
        value >= self.predicate
    }
}
