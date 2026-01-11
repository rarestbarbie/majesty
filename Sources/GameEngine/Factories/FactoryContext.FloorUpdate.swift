import Assert
import GameRules

extension FactoryContext {
    struct FloorUpdate {
        let workersPaid: Int64
        let wagesPaid: Int64
        let hireToday: Int64
        let hireLater: Int64
        let fireToday: Int64
        let fireLater: Int64
    }
}
extension FactoryContext.FloorUpdate {
    static func operate(
        factory: Factory,
        type: FactoryMetadata,
        workers: Workforce,
        budget: Int64,
        turn: inout Turn
    ) -> Self {
        let fireToday: Int64

        let wagesOwed: Int64 = workers.count * factory.z.wn
        if  wagesOwed > budget {
            let limit: Int64 = budget / factory.z.wn
            fireToday = workers.count - limit
        } else {
            fireToday = 0
        }
        /// This can be larger than the actual number of workers available, but it
        /// will never be larger than the number of workers that can fit in the factory
        let optimal: Int64 = factory.inventory.l.width(
            limit: workers.limit,
            tier: type.materials,
            efficiency: factory.z.ei
        )

        #assert(optimal >= 0, "Hours workable (\(optimal)) is negative?!?!")

        let workersPaid: Int64 = min(workers.count - fireToday, optimal)
        let wagesPaid: Int64 = workersPaid <= 0 ? 0 : turn.bank.transfer(
            budget: workersPaid * factory.z.wn,
            source: factory.id.lei,
            recipients: .shuffle(pops: workers.pops, rate: factory.z.wn, using: &turn.random)
        )

        let fireLater: Int64 = workers.count - fireToday - workersPaid

        let hireToday: Int64
        let hireLater: Int64

        if  fireToday > 0 || fireLater > 0 {
            hireToday = 0
            hireLater = 0
        } else {
            // we don’t “just” want to hire the optimal number of workers, we want to hire
            // more, so that the factory can expand, otherwise it will never purchase more
            // materials and the optimal number of workers will never increase.
            let workersNeeded: Int64 = workers.limit - workers.count
            let workersAffordable: Int64 = (budget - wagesPaid) / factory.z.wn
            let workersDesired: Int64 = min(workersNeeded, workersAffordable)

            hireToday = workersDesired <= 0 ? 0 : .random(
                in: 0 ... max(1, workersDesired / 10),
                using: &turn.random.generator
            )
            hireLater = workersDesired - hireToday
        }

        return .init(
            workersPaid: workersPaid,
            wagesPaid: wagesPaid,
            hireToday: hireToday,
            hireLater: hireLater,
            fireToday: fireToday,
            fireLater: fireLater,
        )
    }
}
