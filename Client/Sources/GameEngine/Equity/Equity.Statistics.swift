import Assert
import GameEconomy
import GameState

extension Equity {
    struct Statistics {
        var owners: [Shareholder]
        var shares: (
            outstanding: Int64,
            issued: Int64,
            traded: Int64
        )
    }
}
extension Equity.Statistics {
    init() {
        self.init(owners: [], shares: (outstanding: 0, issued: 0, traded: 0))
    }
}
extension Equity.Statistics {
    func price(valuation: Int64) -> Fraction {
        // This formulation means that if there are no outstanding shares, the price is equal
        // to the valuation. In other words, you can buy the entire company for its valuation.
        valuation %/ (self.shares.outstanding + 1)
    }
}
extension Equity<LegalEntity>.Statistics {
    static func compute(
        from equity: Equity<LegalEntity>,
        in context: GameContext.ResidentPass
    ) -> Self {
        let shares: (outstanding: Int64, bought: Int64, sold: Int64) = equity.shares.reduce(
            into: (0, 0, 0)
        ) {
            $0.outstanding += $1.value.shares
            $0.bought += $1.value.bought
            $0.sold += $1.value.sold
        }

        #assert(
            shares.outstanding >= 0,
            "Outstanding shares (\(shares.outstanding)) cannot be negative!!!"
        )

        return .init(
            owners: equity.shares.values.reduce(into: []) {
                let location: Address
                let culture: String?

                switch $1.id {
                case .pop(let id):
                    guard
                    let pop: Pop = context.pops[id] else {
                        return
                    }

                    location = pop.home
                    culture = pop.nat

                case .factory(let id):
                    guard
                    let factory: Factory = context.factories[id] else {
                        return
                    }

                    location = factory.on
                    culture = nil
                }

                guard
                let country: CountryID = context.planets[location.planet]?.occupied else {
                    return
                }

                $0.append(
                    .init(
                        id: $1.id,
                        shares: $1.shares,
                        bought: $1.bought,
                        sold: $1.sold,
                        country: country,
                        culture: culture
                    )
                )
            },
            shares: (
                outstanding: shares.outstanding,
                issued: shares.sold - shares.bought,
                traded: shares.sold + shares.bought
            )
        )
    }
}
