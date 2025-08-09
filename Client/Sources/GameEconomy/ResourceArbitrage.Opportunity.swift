extension ResourceArbitrage {
    struct Opportunity {
        let market: Fiat
        let profit: Int64
        let volume: Int64
        let bottleneckedOnForex: Bool
    }
}
