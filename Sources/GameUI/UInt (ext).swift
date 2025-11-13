extension UInt {
    @inlinable public static prefix func > (value: Self) -> Indent {
        .init(level: value)
    }
}
