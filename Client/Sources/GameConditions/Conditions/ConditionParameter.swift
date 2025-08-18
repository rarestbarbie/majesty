@frozen public struct ConditionParameter {
    @inlinable init() {}

    @inlinable public static func < <T>(self: Self, value: T) -> ConditionBelow<T> {
        .init(predicate: value)
    }

    @inlinable public static func <= <T>(self: Self, value: T) -> ConditionAtMost<T> {
        .init(predicate: value)
    }

    @inlinable public static func == <T>(self: Self, value: T) -> ConditionIs<T> {
        .init(predicate: value)
    }

    @inlinable public static func != <T>(self: Self, value: T) -> ConditionIsNot<T> {
        .init(predicate: value)
    }

    @inlinable public static func >= <T>(self: Self, value: T) -> ConditionAtLeast<T> {
        .init(predicate: value)
    }

    @inlinable public static func > <T>(self: Self, value: T) -> ConditionAbove<T> {
        .init(predicate: value)
    }
}
