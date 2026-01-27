import D
import Fraction
import GameEconomy
import GameIDs
import GameState
import OrderedCollections

struct EconomicAggregator: ~Copyable {
    private var employment: [EconomicLedger.Regional<PopOccupation>: EconomicLedger.LaborMetrics]
    private var gdp: [EconomicLedger.Regional<EconomicLedger.Industry>: Int64]
    private var resource: [EconomicLedger.Regional<Resource>: TradeVolume]
    // These must be ordered, because floating point summation is not associative.
    private var racial: OrderedDictionary<EconomicLedger.Regional<CultureID>, EconomicLedger.CapitalMetrics>
    private var gender: OrderedDictionary<EconomicLedger.Regional<Gender>, EconomicLedger.CapitalMetrics>
    /// This tracks liquid income only, excluding capital gains from equity ownership.
    private var income: OrderedDictionary<EconomicLedger.IncomeSection, EconomicLedger.IncomeMetrics>
    private var slaves: OrderedDictionary<Address, EconomicLedger.SocialMetrics>

    init() {
        self.employment = [:]
        self.gdp = [:]
        self.resource = [:]
        self.racial = [:]
        self.gender = [:]
        self.income = [:]
        self.slaves = [:]
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
        equity: Equity<LEI>.Statistics,
        region: Address,
        output: ResourceOutputs,
        industry: EconomicLedger.Industry,
    ) {
        let value: Int64 = statement.valueAdded

        self.gdp[region / industry, default: 0] += value

        for (tradeable, output): (tradeable: Bool, ResourceOutput) in output.joined {
            self.countProduction(
                output: output,
                region: region,
                tradeable: tradeable
            )

            guard equity.shareCount > 0 else {
                continue
            }

            let share: Double = Double.init(value %/ equity.shareCount)
            for owner: Equity<LEI>.Statistics.Shareholder in equity.owners {
                let owned: Double = Double.init(owner.shares) * share
                self.racial[owner.region / owner.culture, default: .zero].income += owned
                if  let gender: Gender = owner.gender {
                    self.gender[owner.region / gender, default: .zero].income += owned
                }
            }
        }

        self.countConsumption(inputs: statement.costs.items, region: region)
    }

    /// Miners are never enslaved, so no equity breakdown is necessary.
    mutating func countFree(
        state pop: Pop,
        stats: Pop.Stats,
        account: Bank.Account,
    ) {
        let region: Address = pop.tile
        ; {
            $0.count += pop.z.total
            $0.employed += stats.employedBeforeEgress
        } (&self.employment[region / pop.occupation, default: .zero])

        self.countConsumption(inputs: stats.financial.costs.items, region: region)

        let section: EconomicLedger.IncomeSection = .init(
            stratum: pop.type.stratum,
            gender: pop.type.gender,
            region: region
        )

        let incomeSelfEmployment: Int64
        let income: Double
        if case .Owner = pop.type.stratum {
            // resources produced by aristocrats and politicians are not counted as part of
            // GDP, otherwise campaign contributions would be like, 99 percent of GDP
            incomeSelfEmployment = 0
            /// do not count income from interest and dividends, that was already counted when
            /// we iterated the equity structure of the assets themselves
            income = Double.init(account.s)
        } else {
            incomeSelfEmployment = stats.financial.valueAdded
            income = Double.init(account.s + account.i + incomeSelfEmployment)

            for (tradeable, output): (tradeable: Bool, ResourceOutput) in pop.inventory.out.joined {
                let valueAdded: Int64 = output.valueProduced

                self.gdp[region / .artisan(output.id), default: 0] += valueAdded
                self.countProduction(output: output, region: region, tradeable: tradeable)
            }
            for mining: MiningJob in pop.mines.values {
                for (tradeable, output): (tradeable: Bool, ResourceOutput) in mining.out.joined {
                    let valueAdded: Int64 = output.valueProduced

                    self.gdp[region / .artisan(output.id), default: 0] += valueAdded
                    self.countProduction(output: output, region: region, tradeable: tradeable)
                }
            }
        }

        self.racial[region / pop.type.race, default: .zero].count(pop, income: income)
        self.gender[region / pop.type.gender, default: .zero].count(pop, income: income)
        self.income[section, default: .zero].count(
            free: pop,
            incomeSubsidies: account.s,
            incomeFromEmployment: account.i,
            incomeSelfEmployment: incomeSelfEmployment
        )
    }

    mutating func countSlave(
        state pop: Pop,
        stats: Pop.Stats,
        equity: Equity<LEI>.Statistics,
    ) {
        self.slaves[pop.tile, default: .zero].count(slave: pop)
        self.count(
            statement: stats.financial,
            equity: equity,
            region: pop.tile,
            output: pop.inventory.out,
            industry: .slavery(pop.type.race),
        )
    }
}
extension EconomicAggregator {
    consuming func aggregate() -> EconomicLedger {
        return .init(
            employment: self.employment,
            gdp: self.gdp,
            resource: self.resource,
            racial: self.racial,
            gender: self.gender,
            income: self.income,
            slaves: self.slaves
        )
    }
}
