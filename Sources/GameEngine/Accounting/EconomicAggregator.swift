import D
import Fraction
import GameEconomy
import GameIDs
import GameState
import OrderedCollections

struct EconomicAggregator: ~Copyable {
    private var labor: [EconomicLedger.Regional<PopOccupation>: EconomicLedger.LaborMetrics]
    private var trade: [EconomicLedger.Regional<Resource>: TradeVolume]
    private var gdp: [EconomicLedger.Regional<EconomicLedger.Industry>: Int64]
    // These must be ordered, because floating point summation is not associative.
    private var racial: OrderedDictionary<EconomicLedger.Regional<CultureID>, EconomicLedger.CapitalMetrics>
    private var gender: OrderedDictionary<EconomicLedger.Regional<Gender>, EconomicLedger.CapitalMetrics>
    /// This tracks liquid income only, excluding capital gains from equity ownership.
    private var income: OrderedDictionary<EconomicLedger.IncomeSection, EconomicLedger.IncomeMetrics>
    private var slaves: OrderedDictionary<Address, EconomicLedger.SocialMetrics>

    init() {
        self.labor = [:]
        self.trade = [:]
        self.gdp = [:]
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
            } (&self.trade[region / id, default: .zero])
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
        } (&self.trade[region / output.id, default: .zero])
    }

    private mutating func countDomesticProduct(
        income: Int64,
        region: Address,
        industry: EconomicLedger.Industry
    ) {
        self.gdp[region / industry, default: 0] += income
    }
    private mutating func countNationalProduct(
        income: Int64,
        equity: Equity<LEI>.Statistics
    ) {
        guard equity.shareCount > 0 else {
            return
        }

        let share: Double = Double.init(income %/ equity.shareCount)
        for owner: Equity<LEI>.Statistics.Shareholder in equity.owners {
            let owned: Double = Double.init(owner.shares) * share
            self.racial[owner.region / owner.culture, default: .zero].countCapitalAttributable(
                income: owned
            )
            if  let gender: Gender = owner.gender {
                self.gender[owner.region / gender, default: .zero].countCapitalAttributable(
                    income: owned
                )
            }
        }
    }

    private mutating func countTrade(
        statement: FinancialStatement,
        region: Address,
        output: ResourceOutputs,
    ) {
        self.countConsumption(inputs: statement.costs.items, region: region)
        for (tradeable, output): (tradeable: Bool, ResourceOutput) in output.joined {
            self.countProduction(output: output, region: region, tradeable: tradeable)
        }
    }
}
extension EconomicAggregator {
    mutating func countSocial(slave pop: Pop) {
        self.slaves[pop.tile, default: .zero].count(slave: pop)
    }
    mutating func countSocial(free pop: Pop, stats: Pop.Stats) {
        {
            $0.count += pop.z.total
            $0.employed += stats.employedBeforeEgress
        } (&self.labor[pop.tile / pop.occupation, default: .zero])
    }
}
extension EconomicAggregator {
    mutating func countBusiness(
        state: some LegalEntityState,
        statement: FinancialStatement,
        account: Bank.Account,
        equity: Equity<LEI>.Statistics,
    ) {
        let region: Address = state.tile
        let income: Int64 = statement.incomeUnrealizedGain

        self.countTrade(statement: statement, region: region, output: state.inventory.out)
        self.countDomesticProduct(income: income, region: region, industry: state.industry)
        // before we count GNP, we must deduct labor costs, as well as dividends paid to
        // shareholders, both of which would show up in the recipient’s `account.i`
        self.countNationalProduct(income: income + account.i, equity: equity)
    }

    /// Miners are never enslaved, so no equity breakdown is necessary.
    mutating func countConsumer(
        state pop: Pop,
        statement: FinancialStatement,
        account: Bank.Account,
    ) {
        let region: Address = pop.tile

        self.countConsumption(inputs: statement.costs.items, region: region)

        let section: EconomicLedger.IncomeSection = .init(
            stratum: pop.type.stratum,
            gender: pop.type.gender,
            region: region
        )

        let incomeSelfEmployment: Int64
        if case .Elite = pop.type.stratum {
            // resources produced by aristocrats and politicians are not counted as part of
            // GDP, otherwise campaign contributions would be like, 99 percent of GDP
            incomeSelfEmployment = 0
        } else {
            incomeSelfEmployment = statement.incomeSelfEmployment

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

        let incomeLessTransfers: Int64 = account.i + incomeSelfEmployment
        let incomeFromTransfers: Int64 = account.s

        // this is the equivalent of calling `countNationalProduct`, but with the pop having
        // exactly one shareholder, which is itself
        self.racial[region / pop.type.race, default: .zero].count(
            free: pop,
            incomeLessTransfers: incomeLessTransfers,
            incomeFromTransfers: incomeFromTransfers
        )
        self.gender[region / pop.type.gender, default: .zero].count(
            free: pop,
            incomeLessTransfers: incomeLessTransfers,
            incomeFromTransfers: incomeFromTransfers
        )
        self.income[section, default: .zero].count(
            free: pop,
            incomeLessTransfers: incomeLessTransfers,
            incomeFromTransfers: incomeFromTransfers
        )
    }
}
extension EconomicAggregator {
    consuming func aggregate() -> EconomicLedger {
        return .init(
            labor: self.labor,
            trade: self.trade,
            gdp: self.gdp,
            racial: self.racial,
            gender: self.gender,
            income: self.income,
            slaves: self.slaves
        )
    }
}
