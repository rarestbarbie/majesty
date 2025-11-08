import GameIDs

extension LocalMarket {
    @frozen public struct Order {
        public let by: LEI
        public let tier: UInt8?
        public let memo: MineID?
        public var amount: Int64
        public var filled: Int64

        init(by: LEI, tier: UInt8?, memo: MineID?, amount: Int64, filled: Int64 = 0) {
            self.by = by
            self.tier = tier
            self.memo = memo
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
