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

    private(set) var region: RegionalAuthority?
    private(set) var miners: Workforce

    init(type: MineMetadata, state: Mine) {
        self.type = type
        self.state = state
        self.region = nil
        self.miners = .empty
    }
}
extension MineContext {
    var snapshot: MineSnapshot {
        .init(
            metadata: self.type,
            state: self.state,
            region: self.region?.properties,
            miners: self.miners
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
        self.region = context.planets[self.state.tile]?.authority

        guard
        let region: RegionalProperties = self.region?.properties else {
            return
        }

        self.miners.limit = self.type.width(tile: region, size: self.state.z.size)
    }
}
extension MineContext: AllocatingContext {
    mutating func allocate(turn: inout Turn) {
        guard let region: RegionalProperties = self.region?.properties else {
            return
        }

        let yield: (efficiency: Double, value: Double) = self.type.yield(
            tile: region,
            turn: turn
        )
        self.state.z.efficiency = yield.efficiency
        self.state.z.yield = yield.value
    }
}
extension MineContext {
    mutating func advance(turn: inout Turn) {
        guard let _: RegionalProperties = self.region?.properties else {
            return
        }

        let minersToHire: Int64 = self.miners.limit - self.miners.count
        if  minersToHire > 0 {
            let bid: PopJobOfferBlock = .init(
                job: .mine(self.state.id),
                bid: 1,
                size: .random(
                    in: 0 ... max(1, minersToHire / 25),
                    using: &turn.random.generator
                )
            )

            if  bid.size > 0 {
                turn.jobs.hire.local[self.state.tile, self.type.miner].append(bid)
            }
        } else {
            if  let layoff: PopJobLayoffBlock = .init(size: -minersToHire) {
                turn.jobs.fire[self.state.id, self.type.miner] = layoff
            }
        }

        if  self.type.decay {
            self.state.z.size = max(0, self.state.z.size - self.miners.count)
        }
    }
}
