import D
import Fraction
import GameEconomy
import GameIDs
import GameState
import OrderedCollections

struct EconomicAggregator: ~Copyable {
    private var produced: [EconomicLedger.Regional: (units: Int64, tradeable: CurrencyID?)]
    // These must be ordered, because floating point summation is not associative.
    private var cultural: OrderedDictionary<EconomicLedger.National<CultureID>, Double>
    private var gendered: OrderedDictionary<EconomicLedger.National<Gender>, Double>

    init() {
        self.produced = [:]
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
        let currency: CurrencyID? = tradeable ? region.country.currency.id : nil
        let produced: Int64 = tradeable ? output.units.added : output.unitsSold
        self.produced[region.id / output.id, default: (0, currency)].units += produced
    }
    private mutating func countNational(
        output: ResourceOutput,
        region: RegionalAuthority,
        tradeable: Bool,
        country: CountryID,
        profile: PopType
    ) {
        let produced: Double = .init(tradeable ? output.units.added : output.unitsSold)
        let location: Address? = tradeable ? nil : region.id

        let cultureKey: EconomicLedger.National<CultureID> = .init(
            resource: output.id,
            location: location,
            country: country,
            owner: profile.race
        )
        self.cultural[cultureKey, default: 0] += produced
        let genderKey: EconomicLedger.National<Gender> = .init(
            resource: output.id,
            location: location,
            country: country,
            owner: profile.gender
        )
        self.gendered[genderKey, default: 0] += produced
    }
}
extension EconomicAggregator {
    mutating func count(
        output: ResourceOutputs,
        region: RegionalAuthority,
        equity: Equity<LEI>.Statistics,
    ) {
        let country: CountryID = region.occupiedBy
        for (tradeable, output): (tradeable: Bool, ResourceOutput) in output.joined {
            self.countRegional(output: output, region: region, tradeable: tradeable)

            let share: Double = Double.init(
                (tradeable ? output.units.added : output.unitsSold) %/ equity.shareCount
            )
            for owner: Equity<LEI>.Statistics.Shareholder in equity.owners {
                let owned: Double = Double.init(owner.shares) * share
                let location: Address? = tradeable ? nil : region.id

                if  let culture: CultureID = owner.culture {
                    let cultureKey: EconomicLedger.National<CultureID> = .init(
                        resource: output.id,
                        location: location,
                        country: country,
                        owner: culture
                    )
                    self.cultural[cultureKey, default: 0] += owned
                }
                if  let gender: Gender = owner.gender {
                    let genderKey: EconomicLedger.National<Gender> = .init(
                        resource: output.id,
                        location: location,
                        country: country,
                        owner: gender
                    )
                    self.gendered[genderKey, default: 0] += owned
                }
            }
        }
    }
    /// Miners are never enslaved, so no equity breakdown is necessary.
    mutating func count(
        output pop: Pop,
        region: RegionalAuthority,
    ) {
        let country: CountryID = region.occupiedBy
        for (tradeable, output): (tradeable: Bool, ResourceOutput) in pop.inventory.out.joined {
            self.countRegional(
                output: output,
                region: region,
                tradeable: tradeable
            )
            self.countNational(
                output: output,
                region: region,
                tradeable: tradeable,
                country: country,
                profile: pop.type
            )
        }
        for mining: MiningJob in pop.mines.values {
            for (tradeable, output): (tradeable: Bool, ResourceOutput) in mining.out.joined {
                self.countRegional(
                    output: output,
                    region: region,
                    tradeable: tradeable
                )
                self.countNational(
                    output: output,
                    region: region,
                    tradeable: tradeable,
                    country: country,
                    profile: pop.type
                )
            }
        }
    }

    consuming func aggregate(
        localMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>,
        worldMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>,
    ) -> EconomicLedger {
        let produced: OrderedDictionary<
            EconomicLedger.Regional,
            (units: Int64, value: Double)
        > = .init(
            uniqueKeysWithValues: self.produced.lazy.map {
                let value: Double
                if  let currency: CurrencyID = $1.tradeable {
                    let price: Double = worldMarkets[$0.resource / currency]?.price ?? 0
                    value = Double.init($1.units) * price
                } else if
                    let price: LocalPrice = localMarkets[$0.resource / $0.location]?.today.bid {
                    value = Double.init($1.units) * Double.init(price.value)
                } else {
                    value = 0
                }
                return ($0, (units: $1.units, value: value))
            }
        )
        return .init(
            produced: produced,
            cultural: self.cultural,
            gendered: self.gendered
        )
    }
}
