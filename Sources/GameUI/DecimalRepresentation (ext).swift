import D

extension DecimalRepresentation where Value: DecimalFormattable & AdditiveArithmetic {
    @inlinable public static func <- (self: Self, before: Value) -> TooltipInstruction.Ticker {
        let (sign, magnitude): (Bool?, Value) = before.delta(to: self.value)
        return .init(
            value: "\(self)",
            delta: "\(self.with(value: magnitude))",
            sign: sign.map { $0 ? .pos : .neg }
        )
    }
}
