import GameEconomy

struct FactoryBudget {
    var inputs: Int64
    var clerks: Int64
    var workers: Int64
    var dividend: Int64
    var buybacks: Int64
    var px: Fraction

    init(
        inputs: Int64 = 0,
        clerks: Int64 = 0,
        workers: Int64 = 0,
        dividend: Int64 = 0,
        buybacks: Int64 = 0,
        px: Fraction = 1
    ) {
        self.inputs = inputs
        self.clerks = clerks
        self.workers = workers
        self.dividend = dividend
        self.buybacks = buybacks
        self.px = px
    }
}
