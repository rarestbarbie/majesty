import GameIDs
import GameEconomy

/// Information about mine state passed to ``PopContext``.
struct MiningJobConditions {
    let type: MineType
    let output: ResourceTier
    let factor: Double
}
