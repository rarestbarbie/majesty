@dynamicMemberLookup @frozen public struct Mean<Dimensions> {
    @usableFromInline var fields: Dimensions
    @usableFromInline var weight: Double

    @inlinable public init(fields: Dimensions, weight: Double) {
        self.fields = fields
        self.weight = weight
    }
}
extension Mean {
    @inlinable public var population: Double { self.weight }
}
extension Mean: Equatable where Dimensions: Equatable {}
extension Mean: AdditiveArithmetic where Dimensions: AdditiveArithmetic {
    @inlinable public static var zero: Self { .init(fields: .zero, weight: 0) }

    @inlinable public static func + (self: consuming Self, other: Self) -> Self {
        self += other
        return self
    }
    @inlinable public static func - (self: consuming Self, other: Self) -> Self {
        self -= other
        return self
    }
}
extension Mean where Dimensions: AdditiveArithmetic {
    @inlinable public static func += (self: inout Self, other: Self) {
        self.fields += other.fields
        self.weight += other.weight
    }
    @inlinable public static func -= (self: inout Self, other: Self) {
        self.fields -= other.fields
        self.weight -= other.weight
    }
}
extension Mean where Dimensions: BinaryFloatingPoint {
    @inlinable public var defined: Double? {
        self.weight > 0 ? (Double.init(self.fields) / self.weight) : nil
    }
}
extension Mean where Dimensions: BinaryInteger {
    @inlinable public var defined: Double? {
        self.weight > 0 ? (Double.init(self.fields) / self.weight) : nil
    }
}
extension Mean {
    @inlinable public subscript<T>(
        dynamicMember keyPath: KeyPath<Dimensions, T>
    ) -> Double where T: BinaryFloatingPoint {
        self[dynamicMember: keyPath].defined ?? 0
    }
    @inlinable public subscript<T>(
        dynamicMember keyPath: KeyPath<Dimensions, T>
    ) -> Double where T: BinaryInteger {
        self[dynamicMember: keyPath].defined ?? 0
    }

    @inlinable public subscript<T>(dynamicMember keyPath: KeyPath<Dimensions, T>) -> Mean<T> {
        .init(fields: self.fields[keyPath: keyPath], weight: self.weight)
    }
}
