extension TradeRoute {
    struct Activity {
        var exported: Int64
        var profit: Int64
    }
}
extension TradeRoute.Activity {
    static var zero: Self { .init(exported: 0, profit: 0) }

    mutating func report(exported: Int64, profit: Int64) {
        self.exported += exported
        self.profit += profit
    }
}
