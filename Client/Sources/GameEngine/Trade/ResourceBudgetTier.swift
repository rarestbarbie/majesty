import Fraction

struct ResourceBudgetTier {
    var tradeable: Int64
    var inelastic: Int64

    init(tradeable: Int64 = 0, inelastic: Int64 = 0) {
        self.tradeable = tradeable
        self.inelastic = inelastic
    }
}
extension ResourceBudgetTier {
    var total: Int64 { self.tradeable + self.inelastic }
}
extension ResourceBudgetTier {
    mutating func distribute(
        funds available: Int64,
        inelastic: Int64,
        tradeable: Int64,
    ) {
        guard available > 0 else {
            return
        }

        if let item: [Int64] = [tradeable, inelastic].distribute(available) {
            self.tradeable += item[0]
            self.inelastic += item[1]
        }
    }
    mutating func distribute(
        funds available: Int64,
        inelastic: Int64,
        tradeable: Int64,
        w: Int64,
        c: Int64,
    ) -> (w: Int64, c: Int64)? {
        guard available > 0 else {
            return nil
        }

        if let item: [Int64] = [tradeable, inelastic, w, c].distribute(available) {
            self.tradeable += item[0]
            self.inelastic += item[1]
            return (w: item[2], c: item[3])
        } else {
            return nil
        }
    }
}
