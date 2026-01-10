import Assert
import Fraction
import GameIDs

extension Equity {
    struct Statistics {
        var owners: [Shareholder]
        var shareCount: Int64
        var sharePrice: Fraction
    }
}
extension Equity.Statistics: Sendable where Owner: Sendable {}
extension Equity.Statistics {
    init() {
        self.init(owners: [], shareCount: 0, sharePrice: 0)
    }
}
extension Equity<LEI>.Statistics {
    static func compute(
        equity: Equity<LEI>,
        assets: Int64,
        context: GameContext.LegalPass,
    ) -> Self {
        let shareCount: Int64 = equity.shares.reduce(into: 0) { $0 += $1.value.shares }

        #assert(
            shareCount >= 0,
            "Outstanding shares (\(shareCount)) cannot be negative!!!"
        )

        let sharePrice: Fraction = shareCount > 0 ? assets %/ shareCount : 1

        return .init(
            owners: equity.shares.values.reduce(into: []) {
                let country: CountryID
                let culture: CultureID?
                let gender: Gender?

                switch $1.id {
                case .building(let id):
                    guard
                    let building: BuildingContext = context.buildings[id],
                    let region: RegionalProperties = building.region else {
                        return
                    }

                    country = region.occupiedBy
                    culture = nil
                    gender = nil

                case .factory(let id):
                    guard
                    let factory: FactoryContext = context.factories[id],
                    let region: RegionalProperties = factory.region else {
                        return
                    }

                    country = region.occupiedBy
                    culture = nil
                    gender = nil

                case .pop(let id):
                    guard
                    let pop: PopContext = context.pops[id],
                    let region: RegionalProperties = pop.region else {
                        return
                    }

                    country = region.occupiedBy
                    culture = pop.state.race
                    gender = pop.state.gender
                }

                $0.append(
                    .init(
                        id: $1.id,
                        shares: $1.shares,
                        bought: $1.bought,
                        sold: $1.sold,
                        country: country,
                        culture: culture,
                        gender: gender
                    )
                )
            },
            shareCount: shareCount,
            sharePrice: sharePrice
        )
    }
}
