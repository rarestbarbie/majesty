@dynamicMemberLookup
@frozen public struct TurnDelta<Dimensions> {
    @usableFromInline let yesterday: Dimensions
    @usableFromInline let today: Dimensions
}
extension TurnDelta {
    @inlinable public subscript<T>(dynamicMember keyPath: KeyPath<Dimensions, T>) -> T
        where T: AdditiveArithmetic {
        self.today[keyPath: keyPath] - self.yesterday[keyPath: keyPath]
    }
}
