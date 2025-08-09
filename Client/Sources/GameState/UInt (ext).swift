extension UInt {
    static prefix func > (value: Self) -> TooltipInstructionEncoder.Indent {
        .init(level: value)
    }
}
