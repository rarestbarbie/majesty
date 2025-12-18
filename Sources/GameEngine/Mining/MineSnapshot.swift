import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import Random

struct MineSnapshot: Sendable {
    let type: MineMetadata
    let state: Mine
    let region: RegionalProperties?
    let miners: Workforce
}
