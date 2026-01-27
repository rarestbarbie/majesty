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
        entity: some LegalEntityState,
        account: Bank.Account,
        context: GameContext.LegalPass,
    ) -> Self {
        .compute(
            equity: entity.equity,
            // inventory, not assets, to avoid cratering stock price when expanding factory
            assets: account.balance + entity.z.vv,
            context: context
        )
    }

    private static func compute(
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
                let culture: CultureID
                let region: Address
                let gender: Gender?

                switch $1.id {
                case .reserve(let id):
                    guard
                    let country: Country = context.countries[id] else {
                        return
                    }

                    culture = country.culturePreferred
                    region = country.capital
                    gender = nil

                case .building:
                    fatalError("Buildings may not own equity!!!")

                case .factory:
                    fatalError("Factories may not own equity!!!")

                case .pop(let id):
                    guard
                    let pop: Pop = context.pops[id] else {
                        return
                    }

                    culture = pop.race
                    region = pop.tile
                    gender = pop.gender
                }

                $0.append(
                    .init(
                        id: $1.id,
                        shares: $1.shares.total,
                        bought: $1.shares.added,
                        sold: $1.shares.removed,
                        culture: culture,
                        region: region,
                        gender: gender
                    )
                )
            },
            shareCount: shareCount,
            sharePrice: sharePrice
        )
    }
}
