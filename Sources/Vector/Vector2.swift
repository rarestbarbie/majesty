@frozen public struct Vector2: Equatable, Hashable, Sendable {
    @usableFromInline var storage: SIMD2<Double>

    @inlinable init(storage: SIMD2<Double>) {
        self.storage = storage
    }
}
extension Vector2 {
    @inlinable public init(_ x: Double, _ y: Double) {
        self.init(storage: .init(x, y))
    }

    @inlinable public init(radians: Double) {
        self.init(_cos(radians), -_sin(radians))
    }
}
extension Vector2 {
    @inlinable public static var zero: Self { .init(0, 0) }

    @inlinable public var x: Double {
        get { self.storage.x }
        set { self.storage.x = newValue }
    }

    @inlinable public var y: Double {
        get { self.storage.y }
        set { self.storage.y = newValue }
    }

    @inlinable public var sum: Double { self.storage.sum() }
}
extension Vector2 {
    @inlinable public static func += (self: inout Self, b: Self) {
        self.storage += b.storage
    }
    @inlinable public static func -= (self: inout Self, b: Self) {
        self.storage -= b.storage
    }
    @inlinable public static func *= (self: inout Self, b: Self) {
        self.storage *= b.storage
    }
    @inlinable public static func /= (self: inout Self, b: Self) {
        self.storage /= b.storage
    }
}
extension Vector2 {
    @inlinable public static func += (self: inout Self, b: Double) {
        self.storage += b
    }
    @inlinable public static func -= (self: inout Self, b: Double) {
        self.storage -= b
    }
    @inlinable public static func *= (self: inout Self, b: Double) {
        self.storage *= b
    }
    @inlinable public static func /= (self: inout Self, b: Double) {
        self.storage /= b
    }
}
extension Vector2 {
    @inlinable public static func + (a: Self, b: Self) -> Self {
        .init(storage: a.storage + b.storage)
    }

    @inlinable public static func - (a: Self, b: Self) -> Self {
        .init(storage: a.storage - b.storage)
    }

    @inlinable public static func * (a: Self, b: Self) -> Self {
        .init(storage: a.storage * b.storage)
    }

    @inlinable public static func / (a: Self, b: Self) -> Self {
        .init(storage: a.storage / b.storage)
    }
}
extension Vector2 {
    @inlinable public static func + (a: Self, b: Double) -> Self {
        .init(storage: a.storage + b)
    }
    @inlinable public static func - (a: Self, b: Double) -> Self {
        .init(storage: a.storage - b)
    }
    @inlinable public static func * (a: Self, b: Double) -> Self {
        .init(storage: a.storage * b)
    }
    @inlinable public static func / (a: Self, b: Double) -> Self {
        .init(storage: a.storage / b)
    }
}
extension Vector2 {
    @inlinable public static func + (a: Double, b: Self) -> Self {
        .init(storage: a + b.storage)
    }
    @inlinable public static func - (a: Double, b: Self) -> Self {
        .init(storage: a - b.storage)
    }
    @inlinable public static func * (a: Double, b: Self) -> Self {
        .init(storage: a * b.storage)
    }
    @inlinable public static func / (a: Double, b: Self) -> Self {
        .init(storage: a / b.storage)
    }
}
extension Vector2 {
    @inlinable public static func <> (a: Self, b: Self) -> Double {
        (a.storage * b.storage).sum()
    }
}
extension Vector2: CustomStringConvertible {
    @inlinable public var description: String { "\(self.x),\(self.y)" }
}
