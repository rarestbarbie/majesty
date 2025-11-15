import D
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
    static var efficiencyPoliticiansPerMilitancyPoint: Double { 0.01 }
    static var efficiencyPoliticians: Decimal { 5% }
    static var efficiencyMiners: Decimal { 1% }
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
    mutating func afterIndexCount(world _: borrowing GameWorld, context: ComputationPass) throws {
        if  self.type.decay {
            self.miners.limit = self.state.z.size / 10_000
        } else {
            self.miners.limit = self.state.z.size
        }

        self.region = context.planets[self.state.tile]?.properties
    }
}
extension MineContext {
    mutating func advance(turn: inout Turn) {
        guard let region: RegionalProperties = self.region else {
            return
        }

        let minersToHire: Int64 = self.miners.limit - self.miners.count
        if  minersToHire > 0 {
            let bid: PopJobOfferBlock = .init(
                job: .mine(self.state.id),
                bid: 1,
                size: .random(
                    in: 0 ... max(1, minersToHire / 20),
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

        if case .Politician = self.type.miner {
            let mil: Double = self.region?.pops.free.mil.average ?? 0
            self.state.efficiency = Double.init(
                Self.efficiencyPoliticians
            ) + Self.efficiencyPoliticiansPerMilitancyPoint * mil
        } else {
            let bonus: Decimal = region.occupiedBy.modifiers.miningEfficiency[
                self.state.type
            ]?.value ?? 0
            self.state.efficiency = Double.init(Self.efficiencyMiners + bonus)
        }
    }
}
