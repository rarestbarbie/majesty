import ColorReference
import D
import GameIDs
import GameRules
import GameUI
import OrderedCollections
import VectorCharts

struct EconomicLedger {
    let produced: OrderedDictionary<Regional, (units: Int64, value: Double)>
    let cultural: OrderedDictionary<National<CultureID>, Double>
    let gendered: OrderedDictionary<National<Gender>, Double>

    init(
        produced: OrderedDictionary<Regional, (units: Int64, value: Double)> = [:],
        cultural: OrderedDictionary<National<CultureID>, Double> = [:],
        gendered: OrderedDictionary<National<Gender>, Double> = [:]
    ) {
        self.produced = produced
        self.cultural = cultural
        self.gendered = gendered
    }
}
extension EconomicLedger {
    func breakdownGDP(
        rules: GameMetadata,
        region: Address
    ) -> PieChart<Resource, ColorReference> {
        var values: [(Resource, (Double, ColorReference))] = self.produced.compactMap {
            guard $0.location == region else {
                return nil
            }
            return ($0.resource, ($1.value, .color(rules.resources[$0.resource].color)))
        }
        values.sort { $0.0 < $1.0 }
        return .init(values: values)
    }
}

