@frozen public struct ConditionIsNot<Value>: Condition where Value: Equatable {
    public let predicate: Value

    @inlinable init(predicate: Value) {
        self.predicate = predicate
    }

    @inlinable public static func ~ (value: Value, self: Self) -> Bool {
        value != self.predicate
    }
}
