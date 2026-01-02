import D
import Fraction
import GameEconomy
import GameIDs
import GameState
import OrderedCollections

struct EconomicLedger {
    private var produced: [Regional: (units: Int64, tradeable: CurrencyID?)]
    // These must be ordered, because floating point summation is not associative.
    private var cultural: OrderedDictionary<National<CultureID>, Double>
    private var gendered: OrderedDictionary<National<Gender>, Double>

    init() {
        self.produced = [:]
        self.cultural = [:]
        self.gendered = [:]
    }
}
extension EconomicLedger {
    mutating func count(
        output: ResourceOutputs,
        equity: Equity<LEI>.Statistics,
        region: RegionalAuthority,
    ) {
        for (tradeable, output): (tradeable: Bool, ResourceOutput) in output.joined {
            let regionalKey: Regional = .init(
                resource: output.id,
                location: region.id
            )
            let currency: CurrencyID? = tradeable ? region.country.currency.id : nil
            self.produced[regionalKey, default: (0, currency)].units += output.units.added

            let share: Double = Double.init(output.units.added %/ equity.shareCount)
            for owner: Equity<LEI>.Statistics.Shareholder in equity.owners {
                let owned: Double = Double.init(owner.shares) * share
                let location: Address? = tradeable ? nil : region.id

                if  let culture: CultureID = owner.culture {
                    let cultureKey: National<CultureID> = .init(
                        resource: output.id,
                        location: location,
                        country: region.occupiedBy,
                        owner: culture
                    )
                    self.cultural[cultureKey, default: 0] += owned
                }
                if  let gender: Gender = owner.gender {
                    let genderKey: National<Gender> = .init(
                        resource: output.id,
                        location: location,
                        country: region.occupiedBy,
                        owner: gender
                    )
                    self.gendered[genderKey, default: 0] += owned
                }
            }
        }
    }

    func aggregate(
        context: RuntimeContextTable<CountryContext>,
        markets: (
            segmented: OrderedDictionary<LocalMarket.ID, LocalMarket>,
            tradeable: OrderedDictionary<WorldMarket.ID, WorldMarket>
        )
    ) -> [Regional: (units: Int64, value: Double)] {
        .init(
            uniqueKeysWithValues: self.produced.lazy.map {
                let value: Double
                if  let currency: CurrencyID = $1.tradeable {
                    let price: Double = markets.tradeable[$0.resource / currency]?.price ?? 0
                    value = Double.init($1.units) * price
                } else if
                    let price: Decimal = markets.segmented[
                        $0.resource / $0.location
                    ]?.today.bid.value {
                    value = Double.init($1.units) * Double.init(price)
                } else {
                    value = 0
                }
                return ($0, (units: $1.units, value: value))
            }
        )
    }
}
