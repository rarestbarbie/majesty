extension LocalMarket {
    struct Offer {
        var by: LegalEntity
        var amount: Int64
        var filled: Int64

        init(by: LegalEntity, amount: Int64, filled: Int64 = 0) {
            self.by = by
            self.amount = amount
            self.filled = filled
        }
    }
}
