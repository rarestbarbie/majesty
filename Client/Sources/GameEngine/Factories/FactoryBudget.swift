import GameEconomy

enum FactoryBudget {
    case constructing(Constructing)
    case liquidating(Liquidating)
    case active(Active)
}
extension FactoryBudget {
    static func constructing(
        state: Factory,
    ) -> Self{
        let balance: Int64 = state.cash.balance
        return .constructing(.init(spending: balance / 90))
    }
    static func liquidating(
        state: Factory,
        sharePrice: Fraction
    ) -> Self {
        let balance: Int64 = state.cash.balance
        return .liquidating(
            .init(buybacks: min(balance, max(balance / 100, sharePrice.roundedUp)))
        )
    }
    static func active(
        workers: FactoryContext.Workforce?,
        clerks: FactoryContext.Workforce?,
        state: Factory,
        productivity: Int64,
        inputsCostPerHour: Double
    ) -> Active {
        let c: Double = clerks.map { Double.init(state.today.cn * $0.limit) } ?? 0
        let i: Double
        let w: Double
        if  let workers: FactoryContext.Workforce {
            i = Double.init(
                productivity * workers.limit
            ) * state.today.ei * inputsCostPerHour
            w = Double.init(
                state.today.wn * workers.limit
            )
        } else {
            i = 0
            w = 0
        }

        let balance: Int64 = state.cash.balance

        let l: Int64
        var budget: FactoryBudget.Active

        if  let share: [Int64] = [i, c, w].distribute(balance / 7) {
            budget = .init(inputs: share[0], clerks: share[1], workers: share[2])
            l = Int64.init((i + w).rounded(.up))
        } else {
            budget = .init()
            l = 0
        }

        budget.buybacks = max(0, balance - l) / 365
        budget.dividend = balance <> (2 %/ 10_000)

        return budget
    }
}
