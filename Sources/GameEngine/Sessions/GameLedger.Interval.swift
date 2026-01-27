extension GameLedger {
    struct Interval {
        let economy: EconomicLedger
    }
}
extension GameLedger.Interval {
    init() {
        self.init(
            economy: .init()
        )
    }
}
