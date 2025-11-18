import Fraction
import D

@frozen public struct LocalPrice: Equatable {
    public var value: Decimal

    @inlinable init(value: Decimal) {
        self.value = value
    }
}
extension LocalPrice {
    @inlinable public init(_ fraction: Fraction) {
        guard
        let rounded: Decimal = .roundedToNearest(n: fraction.n, d: fraction.d, digits: 4) else {
            fatalError("LocalPrice cannot represent fraction \(fraction)")
        }
        self.init(value: rounded)
    }
    @inlinable public init() {
        self.init(value: .init(units: Self.low, power: -3))
    }
}
extension LocalPrice: CustomStringConvertible {
    @inlinable public var description: String { self.value.description }
}
extension LocalPrice: LosslessStringConvertible {
    @inlinable public init?(
        _ string: consuming some StringProtocol & RangeReplaceableCollection
    ) {
        guard let decimal: Decimal = .init(string) else {
            return nil
        }
        self.init(value: decimal)
    }
}
extension LocalPrice: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        self.value.units.hash(into: &hasher)
        self.value.power.hash(into: &hasher)
    }
}
extension LocalPrice {
    @inlinable public static var zero: Self { .init(value: .zero) }

    @inline(__always) @inlinable static var cent: Int64 { 100 }
    @inline(__always) @inlinable static var high: Int64 { 9999 }
    @inline(__always) @inlinable static var low: Int64 { 1000 }

    consuming func scaled(by factor: Double, rounding mode: FloatingPointRoundingRule) -> Self {
        self.value.units = Int64.init(
            (Double.init(self.value.units) * factor).rounded(mode)
        )
        return self
    }

    consuming func tickedUp() -> Self {
        self.tickUp()
        return self
    }
    consuming func tickedDown() -> Self {
        self.tickDown()
        return self
    }

    mutating func tickUp() {
        let step: Int64 = self.value.units / Self.cent

        self.value.units += step
        if  self.value.units > Self.high {
            self.value.units /= 10
            self.value.power += 1
        }
    }
    mutating func tickDown() {
        let step: Int64 = self.value.units / Self.cent

        self.value.units -= step
        if  self.value.units < Self.low {
            self.value.units *= 10
            self.value.power -= 1
        }
    }
}
extension LocalPrice: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool { a.value < b.value }
}
