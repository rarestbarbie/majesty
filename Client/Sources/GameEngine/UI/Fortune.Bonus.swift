extension Fortune {
    enum Bonus: FortuneType {
        static var fortune: Fortune? { .bonus }
        static prefix func + (_: Self) {}
    }
}
