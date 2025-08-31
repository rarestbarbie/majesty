import GameEconomy

extension PopBudget {
    struct Tier {
        var trade: Int64
        var local: Int64

        init(trade: Int64 = 0, local: Int64 = 0) {
            self.trade = trade
            self.local = local
        }
    }
}
extension PopBudget.Tier {
    var total: Int64 { self.trade + self.local }
}
extension PopBudget.Tier {
    mutating func distribute(
        funds available: Int64,
        local: Int64,
        trade: Int64,
    ) -> Int64 {
        guard available > 0 else {
            return 0
        }

        let total: Int64 = trade + local
        if  total <= available {
            self.trade += trade
            self.local += local
            return available - total
        }

        if  let item: [Int64] = [trade, local].distribute(available) {
            self.trade += item[0]
            self.local += item[1]
            return 0
        }
        else {
            // All costs zero. This should be impossible, since 0 <= available!
            fatalError("unreachable")
        }
    }
}
