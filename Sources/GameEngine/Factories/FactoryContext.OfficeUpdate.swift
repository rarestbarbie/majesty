import Assert
import GameRules

extension FactoryContext {
    struct OfficeUpdate {
        let bonus: Double
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
        clerks: FactoryContext.ClerkEffects,
        budget: Int64,
        turn: inout Turn
    ) -> Self {
        let salariesOwed: Int64 = clerks.workforce.count * factory.z.cn
        let salariesPaid: Int64 = turn.bank.transfer(
            budget: budget,
            source: factory.id.lei,
            recipients: turn.payscale(shuffling: clerks.workforce.pops, rate: factory.z.cn),
        )

        let fireToday: Int64

        if  salariesPaid < salariesOwed {
            // Not enough money to pay all clerks.
            let limit: Int64 = budget / factory.z.cn
            fireToday = clerks.workforce.count - limit

            #assert(fireToday >= 0, "Computed negative clerks to fire today?!?!")
        } else {
            fireToday = 0
        }

        let fireLater: Int64 = max(0, clerks.workforce.count - clerks.optimal - fireToday)

        let hireToday: Int64
        let hireLater: Int64

        if  fireToday > 0 || fireLater > 0 {
            hireToday = 0
            hireLater = 0
        } else {
            let clerksNeeded: Int64 = clerks.optimal - clerks.workforce.count
            let clerksAffordable: Int64 = (budget - salariesPaid) / factory.z.cn
            let clerksDesired: Int64 = min(clerksNeeded, clerksAffordable)

            hireToday = clerksDesired <= 0 ? 0 : .random(
                in: 0 ... max(1, clerksDesired / 20),
                using: &turn.random.generator
            )
            hireLater = clerksDesired - hireToday
        }

        return .init(
            bonus: clerks.bonus,
            salariesPaid: salariesPaid,
            salariesIdle: max(0, salariesPaid - clerks.optimal * factory.z.cn),
            hireToday: hireToday,
            hireLater: hireLater,
            fireToday: fireToday,
            fireLater: fireLater
        )
    }
}
