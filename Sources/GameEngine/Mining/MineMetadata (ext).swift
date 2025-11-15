import Fraction
import GameIDs
import GameRules

extension MineMetadata {
    func chance(size: Int64, tile: GeologicalType) -> (chance: Fraction, spawn: SpawnWeight)? {
        guard let spawn: SpawnWeight = self.spawn[tile] else {
            return nil
        }

        let (r, d): (Int64, Int64?) = spawn.rate.value.fraction

        guard r > 0 else {
            return nil
        }

        return ((r * self.scale) %/ ((d ?? 1) * size + self.scale), spawn)
    }
}
