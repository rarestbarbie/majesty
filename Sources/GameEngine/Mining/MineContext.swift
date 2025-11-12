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
    mutating func startIndexCount() {
        self.miners = .empty
    }

    mutating func addWorkforceCount(pop: Pop, job: MiningJob) {
        self.miners.count(pop: pop.id, job: job)
    }
}
extension MineContext {
    mutating func compute(world _: borrowing GameWorld, context: ComputationPass) throws {
        if  self.type.decay {
            self.miners.limit = self.state.today.size / 10_000
        } else {
            self.miners.limit = self.state.today.size
        }

        guard
        let tile: PlanetGrid.Tile = context.planets[self.state.tile] else {
            return
        }

        self.region = tile.properties
    }
}
extension MineContext {
    mutating func advance(turn: inout Turn) {
        let minersToHire: Int64 = self.miners.limit - self.miners.count
        if  minersToHire > 0 {
            let bid: PopJobOfferBlock = .init(
                job: .mine(self.state.id),
                bid: 1,
                size: Binomial[minersToHire, 0.05].sample(using: &turn.random.generator)
            )

            if  bid.size > 0 {
                turn.jobs.hire.local[self.state.tile, self.type.miner].append(bid)
            }
        } else {
            let layoff: PopJobLayoffBlock = .init(size: -minersToHire)
            if  layoff.size > 0 {
                turn.jobs.fire[self.state.id, self.type.miner] = layoff
            }
        }

        if  self.type.decay {
            self.state.today.size = max(0, self.state.today.size - self.miners.count)
        }

        if case .Politician = self.type.miner,
            let mil: Double = self.region?.pops.free.mil.average {
            self.state.efficiency = 1 + 0.1 * mil
        } else {
            self.state.efficiency = 0.01
        }
    }
}
