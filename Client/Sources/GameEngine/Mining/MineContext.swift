import GameRules
import GameState
import JavaScriptInterop
import JavaScriptKit
import Random

final class _NoMetadata {
    init() {}
}

struct MineContext: RuntimeContext {
    var state: Mine

    private(set) var governedBy: CountryProperties?
    private(set) var occupiedBy: CountryProperties?

    private(set) var miners: Workforce

    init(type _: _NoMetadata, state: Mine) {
        self.state = state
        self.governedBy = nil
        self.occupiedBy = nil
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
    mutating func compute(map _: borrowing GameMap, context: GameContext.ResidentPass) throws {
        self.miners.limit = self.state.size / 10_000

        guard
        let tile: PlanetGrid.Tile = context.planets[self.state.tile],
        let governedBy: CountryProperties = tile.governedBy,
        let occupiedBy: CountryProperties = tile.occupiedBy else {
            return
        }

        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
    }
}
extension MineContext {
    mutating func advance(map: inout GameMap) {
        let minersToHire: Int64 = self.miners.limit - self.miners.count
        if  minersToHire > 0 {
            let bid: PopJobOfferBlock = .init(
                job: .mine(self.state.id),
                bid: 1,
                size: Binomial[minersToHire, 0.05].sample(using: &map.random.generator)
            )

            if  bid.size > 0 {
                map.jobs.hire.local[self.state.tile, self.state.type.minerPop].append(bid)
            }
        } else {
            let layoff: PopJobLayoffBlock = .init(size: -minersToHire)
            if  layoff.size > 0 {
                map.jobs.fire[self.state.id, self.state.type.minerPop] = layoff
            }
        }

        self.state.size = max(0, self.state.size - self.miners.count)
    }
}
