import GameIDs
import OrderedCollections

struct EconomicLedger {
    let produced: OrderedDictionary<Regional, (units: Int64, value: Double)>
    let cultural: OrderedDictionary<National<CultureID>, Double>
    let gendered: OrderedDictionary<National<Gender>, Double>
}
