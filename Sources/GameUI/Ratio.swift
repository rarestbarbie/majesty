/// A `Ratio` is similar to a ``Fraction``, but is more graceful at handling division by zero.
@frozen public struct Ratio<T> {
    public var selected: T
    public var total: T

    @inlinable public init(selected: T, total: T) {
        self.selected = selected
        self.total = total
    }
}
extension Ratio: Equatable where T: Equatable {}
extension Ratio: AdditiveArithmetic where T: AdditiveArithmetic {
    @inlinable public static var zero: Self { .init(selected: .zero, total: .zero) }

    @inlinable public static func + (a: Self, b: Self) -> Self {
        .init(selected: a.selected + b.selected, total: a.total + b.total)
    }
    @inlinable public static func - (a: Self, b: Self) -> Self {
        .init(selected: a.selected - b.selected, total: a.total - b.total)
    }
}
extension Ratio where T: BinaryFloatingPoint {
    @inlinable public var defined: Double? {
        self.total > 0 ? (Double.init(self.selected) / Double.init(self.total)) : nil
    }
}
extension Ratio where T: BinaryInteger {
    @inlinable public var defined: Double? {
        self.total > 0 ? (Double.init(self.selected) / Double.init(self.total)) : nil
    }
}