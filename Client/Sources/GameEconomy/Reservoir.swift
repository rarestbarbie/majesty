@frozen public struct Reservoir: Equatable, Hashable {
    @usableFromInline var value: Int64
    public var added: Int64
    public var removed: Int64

    @inlinable public init(total value: Int64, added: Int64, removed: Int64) {
        self.value = value
        self.added = added
        self.removed = removed
    }
}
extension Reservoir {
    @inlinable static var zero: Self { .init(total: 0, added: 0, removed: 0) }
}
extension Reservoir {
    @inlinable public var total: Int64 { self.value }
    @inlinable public var change: Int64 { self.added - self.removed }
    @inlinable public var before: Int64 { self.value - self.change }

    @inlinable mutating func turn() {
        self.added = 0
        self.removed = 0
    }
    @inlinable public static func -= (self: inout Self, change: Int64) {
        if  change >= 0 {
            self.value -= change
            self.removed += change
        } else {
            self.value -= change
            self.added -= change
        }
    }
    @inlinable public static func += (self: inout Self, change: Int64) {
        if  change >= 0 {
            self.value += change
            self.added += change
        } else {
            self.value += change
            self.removed -= change
        }
    }
}
