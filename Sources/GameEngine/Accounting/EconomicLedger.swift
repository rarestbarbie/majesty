import Color
import ColorReference
import D
import GameIDs
import GameRules
import GameUI
import OrderedCollections
import VectorCharts

struct EconomicLedger {
    let labor: [Regional<PopOccupation>: EconomicLedger.LaborMetrics]
    let trade: [Regional<Resource>: TradeVolume]
    let gdp: [Regional<Industry>: Int64]
    let racial: OrderedDictionary<Regional<CultureID>, CapitalMetrics>
    let gender: OrderedDictionary<Regional<Gender>, CapitalMetrics>
    let income: OrderedDictionary<IncomeSection, IncomeMetrics>
    let slaves: OrderedDictionary<Address, SocialMetrics>

    init(
        labor: [Regional<PopOccupation>: EconomicLedger.LaborMetrics],
        trade: [Regional<Resource>: TradeVolume],
        gdp: [Regional<Industry>: Int64],
        racial: OrderedDictionary<Regional<CultureID>, CapitalMetrics>,
        gender: OrderedDictionary<Regional<Gender>, CapitalMetrics>,
        income: OrderedDictionary<IncomeSection, IncomeMetrics>,
        slaves: OrderedDictionary<Address, SocialMetrics>
    ) {
        self.labor = labor
        self.gdp = gdp
        self.trade = trade
        self.racial = racial
        self.gender = gender
        self.income = income
        self.slaves = slaves
    }
}
extension EconomicLedger {
    init() {
        self.init(
            labor: [:],
            trade: [:],
            gdp: [:],
            racial: [:],
            gender: [:],
            income: [:],
            slaves: [:]
        )
    }
}
extension EconomicLedger {
    func breakdownIndustries(
        rules: GameMetadata,
        region: Address
    ) -> PieChart<Industry, ColorReference> {
        var values: [(Industry, (Int64, ColorReference))] = self.gdp.compactMap {
            guard $0.location == region else {
                return nil
            }
            let color: Color
            switch $0.crosstab {
            case .building(let type): color = rules.buildings[type]?.color ?? 0xFFFFFF
            case .factory(let type): color = rules.factories[type]?.color ?? 0xFFFFFF
            case .artisan(let type): color = rules.resources[type].color
            case .slavery(let type): color = rules.pops.cultures[type]?.color ?? 0xFFFFFF
            }
            return ($0.crosstab, ($1, .color(color)))
        }
        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }

    func breakdownProduction(
        rules: GameMetadata,
        region: Address
    ) -> (
        produced: PieChart<Resource, ColorReference>,
        consumed: PieChart<Resource, ColorReference>
    ) {
        var values: [
            (Resource, (produced: Int64, consumed: Int64, color: ColorReference))
        ] = self.trade.compactMap {
            guard $0.location == region else {
                return nil
            }
            return (
                $0.crosstab,
                (
                    $1.valueProduced,
                    $1.valueConsumed,
                    .color(rules.resources[$0.crosstab].color)
                )
            )
        }

        values.sort { $0.0 < $1.0 }

        return (
            .init(values: values.lazy.map { ($0, ($1.produced, $1.color)) }),
            .init(values: values.lazy.map { ($0, ($1.consumed, $1.color)) })
        )
    }
}
