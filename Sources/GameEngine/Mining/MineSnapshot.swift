import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import Random

struct MineSnapshot: Differentiable, Sendable {
    let metadata: MineMetadata
    let region: RegionalProperties
    let miners: Workforce

    let id: MineID
    let tile: Address
    let type: MineType
    var last: Mine.Expansion?

    var y: Mine.Dimensions
    var z: Mine.Dimensions
}
extension MineSnapshot {
    init(
        metadata: MineMetadata,
        region: RegionalProperties,
        miners: Workforce,
        state: Mine,
    ) {
        self.metadata = metadata
        self.region = region
        self.miners = miners

        self.id = state.id
        self.tile = state.tile
        self.type = state.type
        self.last = state.last

        self.y = state.y
        self.z = state.z
    }
}
