import D
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
        self.shares.outstanding > 0 ? valuation %/ self.shares.outstanding : 1
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

    func tooltipOwnership(
        culture: String,
        context: GameContext,
    ) -> Tooltip {
        let (share, total): (share: Int64, total: Int64) = self.owners.reduce(
            into: (0, 0)
        ) {
            if case .pop(let id) = $1.id,
                let pop: Pop = context.pops.table.state[id], pop.nat == culture {
                $0.share += $1.shares
            }

            $0.total += $1.shares
        }

        return .instructions(style: .borderless) {
            $0[culture] = (Double.init(share) / Double.init(total))[%3]
        }
    }

    func tooltipOwnership(
        country: CountryID,
        context: GameContext,
    ) -> Tooltip? {
        guard
        let country: Country = context.countries.state[country] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = self.owners.reduce(
            into: (0, 0)
        ) {
            if  $1.country == country.id {
                $0.share += $1.shares
            }

            $0.total += $1.shares
        }

        return .instructions(style: .borderless) {
            $0[country.name] = (Double.init(share) / Double.init(total))[%3]
        }
    }

    func tooltipOwnership() -> Tooltip {
        .instructions {
            $0["Shares outstanding", (-)] = self.shares.outstanding[/3] <- self.shares.outstanding - self.shares.issued
            $0[>] {
                $0["Today’s trading volume"] = self.shares.traded[/3]
            }
        }
    }
}
