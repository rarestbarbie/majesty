import GameIDs

extension ResourceArbitrage {
    struct Opportunity {
        let market: CurrencyID
        let profit: Int64
        let volume: Int64
        let bottleneckedOnForex: Bool
    }
}
