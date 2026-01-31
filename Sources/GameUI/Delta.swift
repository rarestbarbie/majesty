import D

@dynamicMemberLookup @frozen public struct Delta<Dimensions> {
    public let y: Dimensions
    public let z: Dimensions

    @inlinable public init(y: Dimensions, z: Dimensions) {
        self.y = y
        self.z = z
    }
}
extension Delta {
    @inlinable public func map<T>(_ transform: (Dimensions) throws -> T) rethrows -> Delta<T> {
        .init(y: try transform(self.y), z: try transform(self.z))
    }
}
extension Delta: Sendable where Dimensions: Sendable {}
extension Delta where Dimensions: AdditiveArithmetic {
    @inlinable public var value: Dimensions { self.z - self.y }

    @inlinable public static func + (a: Self, b: Self) -> Self {
        .init(y: a.y + b.y, z: a.z + b.z)
    }
    @inlinable public static func - (a: Self, b: Self) -> Self {
        .init(y: a.y - b.y, z: a.z - b.z)
    }

    @inlinable public static func + (a: Dimensions, b: Self) -> Self { b + a }
    @inlinable public static func + (a: Self, b: Dimensions) -> Self {
        .init(y: a.y + b, z: a.z + b)
    }

    @inlinable public static func - (a: Self, b: Dimensions) -> Self {
        .init(y: a.y - b, z: a.z - b)
    }
}
extension Delta where Dimensions: Numeric {
    @inlinable public static func * (a: Dimensions, b: Self) -> Self { b * a }
    @inlinable public static func * (a: Self, b: Dimensions) -> Self {
        .init(y: a.y * b, z: a.z * b)
    }
}
extension Delta where Dimensions: BinaryInteger {
    public func percentage(of total: Self, initial: Double = 0) -> Delta<Double>? {
        guard total.z > 0 else {
            return nil
        }

        let z: Double = Double.init(self.z) / Double.init(total.z)
        let y: Double
        if  total.y > 0 {
            y = Double.init(self.y) / Double.init(total.y)
        } else {
            y = initial
        }
        return .init(y: y, z: z)
    }
}
extension Delta where Dimensions: RandomAccessMapping, Dimensions.Value: AdditiveArithmetic {
    @inlinable public subscript(key: Dimensions.Key) -> Delta<Dimensions.Value>? {
        let y: Dimensions.Value? = self.y[key]
        let z: Dimensions.Value? = self.z[key]
        if  let y: Dimensions.Value {
            return .init(y: y, z: z ?? .zero)
        } else if
            let z: Dimensions.Value {
            return .init(y: y ?? .zero, z: z)
        } else {
            return nil
        }
    }
}
extension Delta where Dimensions: AdditiveArithmetic & DecimalFormattable {
    @inlinable public subscript<Format>(format: Format) -> TooltipInstruction.Ticker
        where Format: DecimalFormat {
        self.z[format] <- self.y
    }
    @inlinable public subscript<Power>(
        format: (Decimal.Ungrouped<Power>.Natural) -> ()
    ) -> TooltipInstruction.Ticker where Power: DecimalPower {
        self.z[format] <- self.y
    }
}
extension Delta where Dimensions: BinaryInteger {
    @inlinable public subscript(format: BigIntFormat) -> TooltipInstruction.Ticker {
        self.z[format] <- self.y
    }
}
extension Delta {
    @inlinable public subscript<T>(dynamicMember keyPath: KeyPath<Dimensions, T>) -> Delta<T> {
        .init(y: self.y[keyPath: keyPath], z: self.z[keyPath: keyPath])
    }
}
