import ColorReference
import D
import GameIDs
import GameRules
import GameUI
import OrderedCollections
import VectorCharts

struct EconomicLedger {
    let valueAdded: [Regional<Industry>: Int64]
    let production: [Regional<Resource>: (units: Int64, value: Int64)]
    let cultural: OrderedDictionary<National<CultureID>, Double>
    let gendered: OrderedDictionary<National<Gender>, Double>

    init(
        valueAdded: [Regional<Industry>: Int64] = [:],
        production: [Regional<Resource>: (units: Int64, value: Int64)] = [:],
        cultural: OrderedDictionary<National<CultureID>, Double> = [:],
        gendered: OrderedDictionary<National<Gender>, Double> = [:]
    ) {
        self.valueAdded = valueAdded
        self.production = production
        self.cultural = cultural
        self.gendered = gendered
    }
}
extension EconomicLedger {
    func breakdownGDP(
        rules: GameMetadata,
        region: Address
    ) -> PieChart<Resource, ColorReference> {
        var values: [(Resource, (Int64, ColorReference))] = self.production.compactMap {
            guard $0.location == region else {
                return nil
            }
            return ($0.crosstab, ($1.value, .color(rules.resources[$0.crosstab].color)))
        }
        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }
}
