extension Fortune {
    @frozen public enum None: FortuneType {
        @inlinable public static var fortune: Fortune? { nil }
    }
}
