import D
import Fraction
import GameEconomy
import GameIDs
import GameState
import OrderedCollections

struct EconomicAggregator: ~Copyable {
    private var valueAdded: [EconomicLedger.Regional<EconomicLedger.Industry>: Int64]
    private var production: [EconomicLedger.Regional<Resource>: (units: Int64, value: Int64)]
    // These must be ordered, because floating point summation is not associative.
    private var cultural: OrderedDictionary<EconomicLedger.National<CultureID>, Double>
    private var gendered: OrderedDictionary<EconomicLedger.National<Gender>, Double>

    init() {
        self.valueAdded = [:]
        self.production = [:]
        self.cultural = [:]
        self.gendered = [:]
    }
}
extension EconomicAggregator {
    private mutating func countRegional(
        output: ResourceOutput,
        region: RegionalAuthority,
        tradeable: Bool
    ) {
        {
            $0.units += tradeable ? output.units.added : output.unitsSold
            $0.value += output.valueProduced
        } (&self.production[region.id / output.id, default: (0, 0)])
    }
}
extension EconomicAggregator {
    mutating func count(
        statement: FinancialStatement,
        region: RegionalAuthority,
        output: ResourceOutputs,
        equity: Equity<LEI>.Statistics,
        industry: EconomicLedger.Industry,
    ) {
        let country: CountryID = region.occupiedBy
        let value: Int64 = statement.valueAdded

        self.valueAdded[region.id / industry, default: 0] += value

        for (tradeable, output): (tradeable: Bool, ResourceOutput) in output.joined {
            self.countRegional(
                output: output,
                region: region,
                tradeable: tradeable
            )

            let share: Double = Double.init(value %/ equity.shareCount)
            for owner: Equity<LEI>.Statistics.Shareholder in equity.owners {
                let owned: Double = Double.init(owner.shares) * share

                self.cultural[country / owner.culture, default: 0] += owned
                if  let gender: Gender = owner.gender {
                    self.gendered[country / gender, default: 0] += owned
                }
            }
        }
    }
    /// Miners are never enslaved, so no equity breakdown is necessary.
    mutating func count(
        statement: FinancialStatement,
        region: RegionalAuthority,
        free pop: Pop,
    ) {
        let country: CountryID = region.occupiedBy
        let value: Double = Double.init(statement.valueAdded)

        self.cultural[country / pop.type.race, default: 0] += value
        self.gendered[country / pop.type.gender, default: 0] += value

        for (tradeable, output): (tradeable: Bool, ResourceOutput) in pop.inventory.out.joined {
            let valueAdded: Int64 = output.valueProduced

            self.valueAdded[region.id / .artisan(output.id), default: 0] += valueAdded
            self.countRegional(output: output, region: region, tradeable: tradeable)
        }
        for mining: MiningJob in pop.mines.values {
            for (tradeable, output): (tradeable: Bool, ResourceOutput) in mining.out.joined {
                let valueAdded: Int64 = output.valueProduced

                self.valueAdded[region.id / .artisan(output.id), default: 0] += valueAdded
                self.countRegional(output: output, region: region, tradeable: tradeable)
            }
        }
    }

    consuming func aggregate() -> EconomicLedger {
        return .init(
            valueAdded: self.valueAdded,
            production: self.production,
            cultural: self.cultural,
            gendered: self.gendered
        )
    }
}
