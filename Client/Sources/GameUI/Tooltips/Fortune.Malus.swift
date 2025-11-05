extension Fortune {
    @frozen public enum Malus: FortuneType {
        @inlinable public static var fortune: Fortune? { .malus }
        @inlinable public static prefix func - (_: Self) {}
    }
}
