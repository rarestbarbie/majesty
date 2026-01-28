import D
import Fraction
import GameEconomy
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

    func chanceNew(
        tile: GeologicalType,
    ) -> (chance: Fraction, spawn: SpawnWeight)? {
        guard let spawn: SpawnWeight = self.spawn[tile] else {
            return nil
        }

        let (r, d): (Int64, Int64?) = spawn.rate.value.fraction

        guard r > 0 else {
            return nil
        }

        return ((r * self.scale) %/ ((d ?? 1) * self.scale), spawn)
    }

    func chance(
        tile: GeologicalType,
        size: Int64,
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

        return ((y.n * r * self.scale) %/ (y.d * ((d ?? 1) * (size + self.scale))), spawn)
    }
}
extension MineMetadata {
    static var efficiencyPoliticiansPerMilitancyPoint: Double { 0.03 }
    static var efficiencyPoliticians: Decimal { 5% }
    static var efficiencyMiners: Decimal { 1% }

    static var width: Decimal { 1‰ }

    func width(tile: RegionalProperties, size: Int64) -> Int64 {
        guard self.decay else {
            return size
        }

        let factor: Decimal

        if  let modifier: Decimal = tile.modifiers.miningWidth[self.id]?.value {
            factor = Self.width + modifier
        } else {
            factor = Self.width
        }

        return min(size, 1 + size <> factor)
    }

    func yield(tile: RegionalProperties, turn: borrowing Turn) -> (
        efficiency: Double,
        value: Double
    ) {
        let efficiency: Double
        if case .Politician = self.miner {
            efficiency = Double.init(
                Self.efficiencyPoliticians
            ) + Self.efficiencyPoliticiansPerMilitancyPoint * tile.stats.voters.μ.mil
        } else {
            let bonus: Decimal = tile.modifiers.miningEfficiency[self.id]?.value ?? 0
            efficiency = Double.init(
                Self.efficiencyMiners + bonus
            )
        }

        var yieldBeforeScaling: Double = 0
        for (id, amount): (Resource, Int64) in self.base.segmented {
            let price: Double = .init(turn.localMarkets[id / tile.id].today.bid.value)
            yieldBeforeScaling += price * Double.init(amount)
        }
        for (id, amount): (Resource, Int64) in self.base.tradeable {
            let price: Double = turn.worldMarkets.price(of: id, in: tile.currency.id)
            yieldBeforeScaling += price * Double.init(amount)
        }

        return (efficiency: efficiency, value: yieldBeforeScaling * efficiency)
    }

    func h²(tile: RegionalProperties, yield: Double) -> Double {
        self.h²(tile: tile.stats, yield: yield)
    }

    func h²(tile: Tile.Stats, yield: Double) -> Double {
        let h: Double = self.h(tile: tile, yield: yield)
        return h * h
    }

    private func h(tile: Tile.Stats, yield: Double) -> Double {
        let incomeAverage: Mean<Int64>?

        switch self.miner.stratum {
        case .Elite:
            incomeAverage = nil
        case .Clerk:
            incomeAverage = tile.incomeUpper.map(\.μ.incomeTotal).all
        case .Worker:
            incomeAverage = tile.incomeLower.map(\.μ.incomeTotal).all
        default:
            fatalError("Invalid miner stratum!!!")
        }

        if  let w0: Double = incomeAverage?.defined, w0 > 0 {
            return min(yield / w0, 1)
        } else {
            return 1
        }
    }
}
