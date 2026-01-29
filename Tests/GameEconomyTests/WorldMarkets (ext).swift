import GameEconomy

extension WorldMarkets {
    public init() {
        let settings: Settings = .init(
            depth: 0,
            rot: 0,
            fee: 0,
            feeBoundary: 1,
            feeSchedule: 0,
            capital: .init(base: 2, quote: 2),
            history: 1,
        )
        self.init(settings: settings, table: [:])
    }
}
