extension Fortune {
    enum Malus: FortuneType {
        static var fortune: Fortune? { .malus }
        static prefix func - (_: Self) {}
    }
}
