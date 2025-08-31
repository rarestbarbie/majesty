import GameEconomy

extension PopBudget {
    struct Tier {
        var tradeable: Int64
        var inelastic: Int64

        init(tradeable: Int64 = 0, inelastic: Int64 = 0) {
            self.tradeable = tradeable
            self.inelastic = inelastic
        }
    }
}
extension PopBudget.Tier {
    var total: Int64 { self.tradeable + self.inelastic }
}
extension PopBudget.Tier {
    mutating func distribute(
        funds available: Int64,
        inelastic: Int64,
        tradeable: Int64,
    ) -> Int64 {
        guard available > 0 else {
            return 0
        }

        let total: Int64 = tradeable + inelastic
        if  total <= available {
            self.tradeable += tradeable
            self.inelastic += inelastic
            return available - total
        }

        if  let item: [Int64] = [tradeable, inelastic].distribute(available) {
            self.tradeable += item[0]
            self.inelastic += item[1]
            return 0
        }
        else {
            // All costs zero. This should be impossible, since 0 <= available!
            fatalError("unreachable")
        }
    }
}
