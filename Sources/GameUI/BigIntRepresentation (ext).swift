import D

extension BigIntRepresentation {
    @inlinable public static func / (self: Self, limit: Value) -> TooltipInstruction.Count {
        return .init(
            value: "\(self)",
            limit: "\(self.map { _ in limit })",
            sign: self.value == limit ? nil : self.value < limit ? .neg : .pos
        )
    }

    @inlinable public static func ^^ (self: Self, change: Value) -> TooltipInstruction.Ticker {
        let delta: Self
        let sign: TooltipInstruction.Sign?
        if change == 0 {
            delta = self.with(value: 0)
            sign = nil
        } else if change < 0 {
            delta = self.with(value: 0 - change)
            sign = .neg
        } else {
            delta = self.with(value: change)
            sign = .pos
        }
        return .init(value: "\(self)", delta: "\(delta)", sign: sign)
    }

    @inlinable public static func <- (self: Self, before: Value) -> TooltipInstruction.Ticker {
        let delta: Self
        let sign: TooltipInstruction.Sign?
        if self.value == before {
            delta = self.with(value: 0)
            sign = nil
        } else if self.value < before {
            delta = self.with(value: before - self.value)
            sign = .neg
        } else {
            delta = self.with(value: self.value - before)
            sign = .pos
        }
        return .init(value: "\(self)", delta: "\(delta)", sign: sign)
    }
}
