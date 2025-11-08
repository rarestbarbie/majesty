public protocol ComparableByRawValue: RawRepresentable, Comparable where RawValue: Comparable {
}
extension ComparableByRawValue {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        a.rawValue < b.rawValue
    }
}
