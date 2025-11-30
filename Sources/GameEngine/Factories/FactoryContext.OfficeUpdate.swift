import Assert
import GameRules

extension FactoryContext {
    struct OfficeUpdate {
        let fk: Double
        let salariesPaid: Int64
        let salariesIdle: Int64
        let hireToday: Int64
        let hireLater: Int64
        let fireToday: Int64
        let fireLater: Int64
    }
}
extension FactoryContext.OfficeUpdate {
    static func operate(
        factory: Factory,
        type: FactoryMetadata,
        workers: Workforce,
        clerks: Workforce,
        budget: OperatingBudget,
        turn: inout Turn
    ) -> Self {
        let salariesOwed: Int64 = clerks.count * factory.z.cn
        let salariesPaid: Int64 = turn.bank.transfer(
            budget: budget.clerks,
            source: factory.id.lei,
            recipients: turn.payscale(shuffling: clerks.pops, rate: factory.z.cn),
        )

        let fireToday: Int64

        if  salariesPaid < salariesOwed {
            // Not enough money to pay all clerks.
            let limit: Int64 = budget.clerks / factory.z.cn
            fireToday = clerks.count - limit

            #assert(fireToday >= 0, "Computed negative clerks to fire today?!?!")
        } else {
            fireToday = 0
        }

        let clerkHorizon: Int64 = type.clerkHorizon(for: workers.count)
        let fk: Double = clerks.count < clerkHorizon
                ? Double.init(clerks.count) / Double.init(clerkHorizon)
                : 1

        // the `optimal` might not be very optimal for the factory as a whole if the clerks
        // themselves are very expensive, so we scale it by the budget’s suggested `fk` target
        let clerksTarget: Int64 = .init(budget.fk * Double.init(clerkHorizon))
        let fireLater: Int64 = max(0, clerks.count - clerksTarget - fireToday)

        let hireToday: Int64
        let hireLater: Int64

        if  fireToday > 0 || fireLater > 0 {
            hireToday = 0
            hireLater = 0
        } else {
            let clerksNeeded: Int64 = clerksTarget - clerks.count
            let clerksAffordable: Int64 = (budget.clerks - salariesPaid) / factory.z.cn
            let clerksDesired: Int64 = min(clerksNeeded, clerksAffordable)

            hireToday = clerksDesired <= 0 ? 0 : .random(
                in: 0 ... max(1, clerksDesired / 20),
                using: &turn.random.generator
            )
            hireLater = clerksDesired - hireToday
        }

        return .init(
            fk: fk,
            salariesPaid: salariesPaid,
            salariesIdle: max(0, salariesPaid - clerksTarget * factory.z.cn),
            hireToday: hireToday,
            hireLater: hireLater,
            fireToday: fireToday,
            fireLater: fireLater
        )
    }
}
