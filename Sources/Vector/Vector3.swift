@frozen public struct Vector3: Equatable, Hashable, Sendable {
    @usableFromInline var storage: SIMD3<Double>

    @inlinable init(storage: SIMD3<Double>) {
        self.storage = storage
    }
}
extension Vector3 {
    @inlinable public init(_ x: Double, _ y: Double, _ z: Double) {
        self.init(storage: .init(x, y, z))
    }
}
extension Vector3 {
    @inlinable public static var zero: Self { .init(0, 0, 0) }

    @inlinable public var x: Double {
        get { self.storage.x }
        set { self.storage.x = newValue }
    }

    @inlinable public var y: Double {
        get { self.storage.y }
        set { self.storage.y = newValue }
    }

    @inlinable public var z: Double {
        get { self.storage.z }
        set { self.storage.z = newValue }
    }

    @inlinable public var sum: Double { self.storage.sum() }
}
extension Vector3 {
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
extension Vector3 {
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
extension Vector3 {
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
extension Vector3 {
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
extension Vector3 {
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
extension Vector3 {
    @inlinable public static func <> (a: Self, b: Self) -> Double {
        (a.storage * b.storage).sum()
    }

    @inlinable public static func >< (a: Self, b: Self) -> Self {
        let a1: SIMD3<Double> = .init(a.storage.y, a.storage.z, a.storage.x)
        let a2: SIMD3<Double> = .init(a.storage.z, a.storage.x, a.storage.y)
        let b1: SIMD3<Double> = .init(b.storage.z, b.storage.x, b.storage.y)
        let b2: SIMD3<Double> = .init(b.storage.y, b.storage.z, b.storage.x)

        return .init(storage: a1 * b1 - a2 * b2)
    }
}
extension Vector3: CustomStringConvertible {
    @inlinable public var description: String { "\(self.x),\(self.y),\(self.z)" }
}
