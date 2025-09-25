import GameEconomy

struct PopBudget {
    var l: Tier
    var e: Tier
    var x: Tier
    var dividend: Int64
    var buybacks: Int64
    var px: Fraction

    init() {
        self.l = .init()
        self.e = .init()
        self.x = .init()
        self.dividend = 0
        self.buybacks = 0
        self.px = 1
    }
}
