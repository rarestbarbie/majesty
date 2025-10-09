import GameState

extension LocalMarket {
    struct Order {
        let by: LEI
        let tier: UInt8?
        var amount: Int64
        var filled: Int64

        init(by: LEI, tier: UInt8?, amount: Int64, filled: Int64 = 0) {
            self.by = by
            self.tier = tier
            self.amount = amount
            self.filled = filled
        }
    }
}
extension LocalMarket.Order {
    mutating func fillAll() {
        self.filled = self.amount
    }
}
