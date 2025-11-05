extension UInt {
    @inlinable public static prefix func > (value: Self) -> TooltipInstructionEncoder.Indent {
        .init(level: value)
    }
}
