import D
import GameEconomy
import GameIDs
import GameUI

protocol LegalEntitySnapshot<State>: Identifiable {
    associatedtype State: LegalEntityState

    var region: RegionalProperties { get }
    var equity: Equity<LEI>.Statistics { get }
    var state: State { get }

    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: WorldMarket.State?)
    ) -> Tooltip?
}
extension LegalEntitySnapshot {
    var id: State.ID { self.state.id }
}
extension LegalEntitySnapshot {
    func tooltipStockpile(
        _ resource: InventoryLine,
    ) -> Tooltip? {
        switch resource {
        case .l(let id): self.state.inventory.l.tooltipStockpile(id, region: self.region)
        case .e(let id): self.state.inventory.e.tooltipStockpile(id, region: self.region)
        case .x(let id): self.state.inventory.x.tooltipStockpile(id, region: self.region)
        case .o: nil
        case .m: nil
        }
    }
}
extension LegalEntitySnapshot {
    func tooltipOwnership(
        culture: CultureID,
        context: GameUI.CacheContext,
    ) -> Tooltip? {
        guard
        let culture: Culture = context.rules.pops.cultures[culture] else {
            return nil
        }
        let (share, total): (share: Int64, total: Int64) = self.equity.owners.reduce(
            into: (0, 0)
        ) {
            if case culture.id? = $1.culture {
                $0.share += $1.shares
            }

            $0.total += $1.shares
        }

        return .instructions(style: .borderless) {
            $0[culture.name] = (Double.init(share) / Double.init(total))[%3]
            $0[>] = "The \(em: culture.name) shareholders own \(em: share[/3]) shares"
        }
    }

    func tooltipOwnership(
        country: CountryID,
        context: GameUI.CacheContext,
    ) -> Tooltip? {
        guard
        let country: Country = context.countries[country] else {
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
            $0[country.name.short] = (Double.init(share) / Double.init(total))[%3]
            $0[>] = "The residents of \(em: country.name.short) own \(em: share[/3]) shares"
        }
    }

    func tooltipOwnership() -> Tooltip {
        let equity: Equity<LEI> = self.state.equity
        return .instructions {
            $0["Shares outstanding", (-)] = self.equity.shareCount[/3] ^^ equity.issued
            $0[>] {
                $0["Today’s trading volume"] = equity.traded[/3]
            }
            if  let last: EquitySplit = equity.splits.last {
                let factor: EquitySplit.Factor = last.factor
                switch factor {
                case .reverse:
                    $0[>] = """
                    This stock most recently underwent \(factor.articleIndefinite) \
                    \(neg: factor) reverse split on \(em: last.date[.phrasal_US])
                    """

                    var times: Int = 0
                    for split: EquitySplit in equity.splits.reversed() {
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
                    \(pos: factor) stock split on \(em: last.date[.phrasal_US])
                    """

                    var times: Int = 0
                    for split: EquitySplit in equity.splits.reversed() {
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
