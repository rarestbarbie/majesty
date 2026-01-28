import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import Random

struct MineContext: RuntimeContext {
    let type: MineMetadata
    var state: Mine

    private(set) var region: RegionalProperties?
    private(set) var miners: Workforce

    init(type: MineMetadata, state: Mine) {
        self.type = type
        self.state = state
        self.region = nil
        self.miners = .empty
    }
}
extension MineContext {
    var snapshot: MineSnapshot? {
        guard let region: RegionalProperties = self.region else {
            return nil
        }

        return .init(
            metadata: self.type,
            region: region,
            miners: self.miners,
            state: self.state,
        )
    }
}
extension MineContext {
    mutating func startIndexCount() {
        self.miners = .empty
    }

    mutating func addWorkforceCount(pop: Pop, job: MiningJob) {
        self.miners.count(pop: pop.id, job: job)
    }
}
extension MineContext {
    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: ComputationPass
    ) throws {
        self.region = context.tiles[self.state.tile]?.properties

        guard
        let region: RegionalProperties = self.region else {
            return
        }

        self.miners.limit = self.state.z.parcels * self.type.width(
            tile: region,
            size: self.state.z.size
        )
    }
}
extension MineContext: AllocatingContext {
    mutating func allocate(turn: inout Turn) {
        guard let region: RegionalProperties = self.region else {
            return
        }

        let yield: (efficiency: Double, value: Double) = self.type.yield(
            tile: region,
            turn: turn
        )
        self.state.z.efficiency = yield.efficiency
        self.state.z.yieldBase = yield.value
    }
}
extension MineContext {
    static var h0: Double { 0.04 }
}
extension MineContext {
    mutating func advance(turn: inout Turn) {
        guard let region: RegionalProperties = self.region else {
            return
        }

        let minersToHire: Int64 = self.miners.limit - self.miners.count
        let minersToHireToday: Int64
        let h: Double = self.type.h(tile: region.stats, yield: self.state.z.yield)

        if  minersToHire > 0 {
            let h²: Double = MineMetadata.h²(h: h)

            let minersTarget: Double = Self.h0 * h² * Double.init(minersToHire)
            if  minersTarget < 1 {
                let roll: Double = Double.random(in: 0 ... 1, using: &turn.random.generator)
                minersToHireToday = roll < minersTarget ? 1 : 0
            } else {
                minersToHireToday = .random(
                    in: 0 ... min(Int64.init(minersTarget.rounded()), minersToHire),
                    using: &turn.random.generator
                )
            }

            if  minersToHireToday > 0 {
                let market: LaborMarket.Regionwide = .init(
                    id: self.state.tile,
                    type: self.type.miner
                )
                let bid: PopJobOfferBlock = .init(
                    job: .mine(self.state.id),
                    bid: 1,
                    size: minersToHireToday
                )
                turn.jobs.hire.region[market].append(bid)
            }
        } else {
            if  let layoff: PopJobLayoffBlock = .init(size: -minersToHire) {
                turn.jobs.fire[self.state.id, self.type.miner] = layoff
            }

            minersToHireToday = 0
        }

        if  self.type.decay {
            let (q, r): (Int64, Int64) = self.miners.count.quotientAndRemainder(
                dividingBy: self.state.z.parcels
            )
            let consumed: Int64 = r > 0 ? q + 1 : q
            self.state.z.size = max(0, self.state.z.size - consumed)

            if  h < 0.25 {
                let minersPossible: Int64 = self.miners.count + minersToHireToday
                if  self.state.z.splits > 0, minersPossible * 8 < self.miners.limit {
                    self.state.z.splits -= 1
                }
            } else if h > 2 {
                if  self.state.z.splits < 10, self.miners.count * 8 > self.miners.limit * 7 {
                    self.state.z.splits += 1
                }
            }
        }
    }
}
