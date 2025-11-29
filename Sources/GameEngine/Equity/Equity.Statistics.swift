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
extension Equity.Statistics {
    init() {
        self.init(owners: [], shareCount: 0, sharePrice: 0)
    }
}
extension Equity<LEI>.Statistics {
    static func compute(
        equity: Equity<LEI>,
        assets: Bank.Account,
        in context: GameContext.ResidentPass,
    ) -> Self {
        let shareCount: Int64 = equity.shares.reduce(into: 0) { $0 += $1.value.shares }

        #assert(
            shareCount >= 0,
            "Outstanding shares (\(shareCount)) cannot be negative!!!"
        )

        // This formulation means that if there are no outstanding shares, the price is equal
        // to the valuation. In other words, you can buy the entire company for its valuation.
        let sharePrice: Fraction = assets.balance %/ max(shareCount, 1)

        return .init(
            owners: equity.shares.values.reduce(into: []) {
                let location: Address
                let culture: CultureID?

                switch $1.id {
                case .building(let id):
                    guard
                    let building: Building = context.buildings[id] else {
                        return
                    }

                    location = building.tile
                    culture = nil

                case .factory(let id):
                    guard
                    let factory: Factory = context.factories[id] else {
                        return
                    }

                    location = factory.tile
                    culture = nil

                case .pop(let id):
                    guard
                    let pop: Pop = context.pops[id] else {
                        return
                    }

                    location = pop.tile
                    culture = pop.race
                }

                guard
                let region: RegionalAuthority = context.planets[location]?.authority else {
                    return
                }

                $0.append(
                    .init(
                        id: $1.id,
                        shares: $1.shares,
                        bought: $1.bought,
                        sold: $1.sold,
                        country: region.governedBy,
                        culture: culture
                    )
                )
            },
            shareCount: shareCount,
            sharePrice: sharePrice
        )
    }
}
