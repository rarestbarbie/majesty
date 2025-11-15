import Fraction
import GameIDs
import GameRules

extension MineMetadata {
    static func yieldRankExpansionFactor(_ yieldRank: Int) -> Fraction? {
        switch yieldRank {
        case 0: return 1
        case 1: return 1 %/ 2
        case _: return nil
        }
    }

    func chance(
        size: Int64,
        tile: GeologicalType,
        yieldRank: Int
    ) -> (chance: Fraction, spawn: SpawnWeight)? {
        guard let y: Fraction = Self.yieldRankExpansionFactor(yieldRank) else {
            return nil
        }

        guard let spawn: SpawnWeight = self.spawn[tile] else {
            return nil
        }

        let (r, d): (Int64, Int64?) = spawn.rate.value.fraction

        guard r > 0 else {
            return nil
        }

        return ((y.n * r * self.scale) %/ (y.d * ((d ?? 1) * size + self.scale)), spawn)
    }
}
