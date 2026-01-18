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
        let shareCount: Int64 = equity.shares.reduce(into: 0) { $0 += $1.value.shares.total }

        #assert(
            shareCount >= 0,
            "Outstanding shares (\(shareCount)) cannot be negative!!!"
        )

        let sharePrice: Fraction = assets %/ max(1, shareCount)

        return .init(
            owners: equity.shares.values.reduce(into: []) {
                let country: CountryID
                let culture: CultureID
                let gender: Gender?

                switch $1.id {
                case .reserve(let id):
                    guard
                    let context: CountryContext = context.countries[id] else {
                        return
                    }

                    country = id
                    culture = context.state.culturePreferred
                    gender = nil

                case .building:
                    fatalError("Buildings may not own equity!!!")

                case .factory:
                    fatalError("Factories may not own equity!!!")

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
                        shares: $1.shares.total,
                        bought: $1.shares.added,
                        sold: $1.shares.removed,
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
