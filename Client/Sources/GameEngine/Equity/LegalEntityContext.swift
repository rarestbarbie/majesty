import D
import GameState

protocol LegalEntityContext<State> {
    associatedtype State: Turnable where State.Dimensions: LegalEntityMetrics
    var equity: Equity<LegalEntity>.Statistics { get }
    var equitySplits: [EquitySplit] { get }
    var state: State { get }
}
extension LegalEntityContext {
    func tooltipOwnership(
        culture: String,
        context: GameContext,
    ) -> Tooltip {
        let (share, total): (share: Int64, total: Int64) = self.equity.owners.reduce(
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
            $0[>] = "The \(em: culture) shareholders own \(em: share[/3]) shares"
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

        let (share, total): (share: Int64, total: Int64) = self.equity.owners.reduce(
            into: (0, 0)
        ) {
            if  $1.country == country.id {
                $0.share += $1.shares
            }

            $0.total += $1.shares
        }

        return .instructions(style: .borderless) {
            $0[country.name] = (Double.init(share) / Double.init(total))[%3]
            $0[>] = "The residents of \(em: country.name) own \(em: share[/3]) shares"
        }
    }

    func tooltipOwnership() -> Tooltip {
        .instructions {
            $0["Shares outstanding", (-)] = self.equity.shares.outstanding[/3]
                ^^ self.equity.shares.issued
            $0[>] {
                $0["Today’s trading volume"] = self.equity.shares.traded[/3]
            }
            if  let last: EquitySplit = self.equitySplits.last {
                let factor: EquitySplit.Factor = last.factor
                switch factor {
                case .reverse:
                    $0[>] = """
                    This stock most recently underwent \(factor.articleIndefinite) \
                    \(neg: factor) reverse split on \(last.date[.phrasal_US])
                    """

                    var times: Int = 0
                    for split: EquitySplit in self.equitySplits.reversed() {
                        guard case .reverse = split.factor else {
                            break
                        }
                        times += 1
                    }
                    if  times > 1 {
                        $0[>] = "It has split \(neg: times) times"
                    }
                case .forward:
                    $0[>] = """
                    This stock most recently underwent \(factor.articleIndefinite) \
                    \(pos: factor) stock split on \(last.date[.phrasal_US])
                    """

                    var times: Int = 0
                    for split: EquitySplit in self.equitySplits.reversed() {
                        guard case .forward = split.factor else {
                            break
                        }
                        times += 1
                    }
                    if  times > 1 {
                        $0[>] = "It has split \(pos: times) times"
                    }
                }
            }
        }
    }
}
