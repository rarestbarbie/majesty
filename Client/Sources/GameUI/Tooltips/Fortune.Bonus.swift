extension Fortune {
    @frozen public enum Bonus: FortuneType {
        @inlinable public static var fortune: Fortune? { .bonus }
        @inlinable public static prefix func + (_: Self) {}
    }
}
