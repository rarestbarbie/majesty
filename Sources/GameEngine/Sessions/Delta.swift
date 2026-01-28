import GameUI
import D

@dynamicMemberLookup struct Delta<Dimensions> {
    let y: Dimensions
    let z: Dimensions

    init(y: Dimensions, z: Dimensions) {
        self.y = y
        self.z = z
    }
}
extension Delta where Dimensions: AdditiveArithmetic {
    var value: Dimensions { self.z - self.y }

    static func + (a: Self, b: Self) -> Self {
        .init(y: a.y + b.y, z: a.z + b.z)
    }
    static func - (a: Self, b: Self) -> Self {
        .init(y: a.y - b.y, z: a.z - b.z)
    }

    static func + (a: Dimensions, b: Self) -> Self { b + a }
    static func + (a: Self, b: Dimensions) -> Self {
        .init(y: a.y + b, z: a.z + b)
    }

    static func - (a: Self, b: Dimensions) -> Self {
        .init(y: a.y - b, z: a.z - b)
    }
}
extension Delta where Dimensions: Numeric {
    static func * (a: Dimensions, b: Self) -> Self { b * a }
    static func * (a: Self, b: Dimensions) -> Self {
        .init(y: a.y * b, z: a.z * b)
    }
}
extension Delta where Dimensions: BinaryInteger {
    func percentage(of total: Self, initial: Double = 0) -> Delta<Double>? {
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
    subscript(key: Dimensions.Key) -> Delta<Dimensions.Value>? {
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
    subscript<Format>(format: Format) -> TooltipInstruction.Ticker
        where Format: DecimalFormat {
        self.z[format] <- self.y
    }
    subscript<Power>(
        format: (Decimal.Ungrouped<Power>.Natural) -> ()
    ) -> TooltipInstruction.Ticker where Power: DecimalPower {
        self.z[format] <- self.y
    }
}
extension Delta where Dimensions: BinaryInteger {
    subscript(format: BigIntFormat) -> TooltipInstruction.Ticker {
        self.z[format] <- self.y
    }
}
extension Delta {
    subscript<T>(dynamicMember keyPath: KeyPath<Dimensions, T>) -> Delta<T> {
        .init(y: self.y[keyPath: keyPath], z: self.z[keyPath: keyPath])
    }
}
