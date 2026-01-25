import D
import Fraction
import GameEconomy
import GameIDs
import GameState
import OrderedCollections

struct EconomicAggregator: ~Copyable {
    private var valueAdded: [EconomicLedger.Regional<EconomicLedger.Industry>: Int64]
    private var resource: [EconomicLedger.Regional<Resource>: TradeVolume]
    // These must be ordered, because floating point summation is not associative.
    private var byCulture: OrderedDictionary<EconomicLedger.National<CultureID>, Double>
    private var byGender: OrderedDictionary<EconomicLedger.National<Gender>, Double>
    private var byIncome: OrderedDictionary<EconomicLedger.IncomeSection, EconomicLedger.LinearMetrics>

    init() {
        self.valueAdded = [:]
        self.resource = [:]
        self.byCulture = [:]
        self.byGender = [:]
        self.byIncome = [:]
    }
}
extension EconomicAggregator {
    private mutating func countConsumption(
        inputs: [FinancialStatement.Cost],
        region: Address,
    ) {
        for case .resource(id: let id, units: let units, value: let value) in inputs {
            {
                $0.unitsConsumed += units
                $0.valueConsumed += value
            } (&self.resource[region / id, default: .zero])
        }
    }
    private mutating func countProduction(
        output: ResourceOutput,
        region: Address,
        tradeable: Bool
    ) {
        {
            $0.unitsProduced += tradeable ? output.units.added : output.unitsSold
            $0.valueProduced += output.valueProduced
        } (&self.resource[region / output.id, default: .zero])
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
            self.countProduction(
                output: output,
                region: region.id,
                tradeable: tradeable
            )

            let share: Double = Double.init(value %/ equity.shareCount)
            for owner: Equity<LEI>.Statistics.Shareholder in equity.owners {
                let owned: Double = Double.init(owner.shares) * share

                self.byCulture[country / owner.culture, default: 0] += owned
                if  let gender: Gender = owner.gender {
                    self.byGender[country / gender, default: 0] += owned
                }
            }
        }

        self.countConsumption(inputs: statement.costs.items, region: region.id)
    }
    /// Miners are never enslaved, so no equity breakdown is necessary.
    mutating func countFreePop(
        statement: FinancialStatement,
        region: RegionalAuthority,
        worker pop: Pop,
    ) {
        let country: CountryID = region.occupiedBy
        let value: Double = Double.init(statement.valueAdded)

        self.byCulture[country / pop.type.race, default: 0] += value
        self.byGender[country / pop.type.gender, default: 0] += value

        for (tradeable, output): (tradeable: Bool, ResourceOutput) in pop.inventory.out.joined {
            let valueAdded: Int64 = output.valueProduced

            self.valueAdded[region.id / .artisan(output.id), default: 0] += valueAdded
            self.countProduction(output: output, region: region.id, tradeable: tradeable)
        }
        for mining: MiningJob in pop.mines.values {
            for (tradeable, output): (tradeable: Bool, ResourceOutput) in mining.out.joined {
                let valueAdded: Int64 = output.valueProduced

                self.valueAdded[region.id / .artisan(output.id), default: 0] += valueAdded
                self.countProduction(output: output, region: region.id, tradeable: tradeable)
            }
        }

        self.countConsumption(inputs: statement.costs.items, region: region.id)
    }
    mutating func countFreePop(
        statement: FinancialStatement,
        region: Address,
    ) {
        self.countConsumption(inputs: statement.costs.items, region: region)
    }

    mutating func countIncome(
        account: Bank.Account,
        region: Address,
        worker pop: Pop,
    ) {
        let section: EconomicLedger.IncomeSection = .init(
            stratum: pop.type.stratum,
            gender: pop.type.gender,
            region: region
        )

        self.byIncome[section, default: .zero].count(account, of: pop)
    }

    consuming func aggregate() -> EconomicLedger {
        return .init(
            valueAdded: self.valueAdded,
            resource: self.resource,
            byCulture: self.byCulture,
            byGender: self.byGender,
            byIncome: self.byIncome
        )
    }
}
