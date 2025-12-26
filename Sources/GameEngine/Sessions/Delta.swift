import GameUI
import D

@dynamicMemberLookup struct Delta<Dimensions> {
    private let y: Dimensions
    private let z: Dimensions

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
}
extension Delta where Dimensions: AdditiveArithmetic & DecimalFormattable {
    subscript<Format>(format: Format) -> TooltipInstruction.Ticker
        where Format: DecimalFormat {
        self.z[format] <- self.y
    }
    subscript<Format>(
        format: (Decimal.NaturalPrecision<Format>) -> ()
    ) -> TooltipInstruction.Ticker where Format: DecimalFormat {
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
