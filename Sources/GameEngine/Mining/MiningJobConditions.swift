import GameIDs
import GameEconomy

/// Information about mine state passed to ``PopContext``.
struct MiningJobConditions {
    let output: ResourceTier
    let efficiencyPerMiner: Double
}
