import GameUI
import D

@dynamicMemberLookup struct TurnDelta<Dimensions> {
    private let y: Dimensions
    private let z: Dimensions

    init(y: Dimensions, z: Dimensions) {
        self.y = y
        self.z = z
    }
}
extension TurnDelta where Dimensions: AdditiveArithmetic {
    var value: Dimensions { self.z - self.y }

    static func + (a: Self, b: Self) -> Self {
        .init(y: a.y + b.y, z: a.z + b.z)
    }
    static func - (a: Self, b: Self) -> Self {
        .init(y: a.y - b.y, z: a.z - b.z)
    }
}
extension TurnDelta where Dimensions: AdditiveArithmetic & DecimalFormattable {
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
extension TurnDelta where Dimensions: BinaryInteger {
    subscript(format: BigIntFormat) -> TooltipInstruction.Ticker {
        self.z[format] <- self.y
    }
}
extension TurnDelta {
    subscript<T>(dynamicMember keyPath: KeyPath<Dimensions, T>) -> TurnDelta<T> {
        .init(y: self.y[keyPath: keyPath], z: self.z[keyPath: keyPath])
    }
}
