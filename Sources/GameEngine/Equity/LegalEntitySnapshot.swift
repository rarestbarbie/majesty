import D
import GameEconomy
import GameIDs
import GameUI
import ColorText

protocol LegalEntitySnapshot<ID>: Differentiable, Identifiable
    where Dimensions: LegalEntityMetrics {
    var tile: Address { get }

    var region: RegionalProperties { get }
    var equity: Equity<LEI>.Snapshot { get }
    var inventory: InventorySnapshot { get }
}
extension LegalEntitySnapshot {
    func tooltipStockpile(
        _ line: InventoryLine,
    ) -> Tooltip? {
        if  case .consumed(let id) = line.query {
            return self.inventory[id]?.tooltipStockpile(region: self.region)
        } else {
            return nil
        }
    }

    func tooltipExplainPrice(
        _ line: InventoryLine,
        context: GameUI.CacheContext,
    ) -> Tooltip? {

        let resource: Resource = line.resource
        let market: (
            segmented: LocalMarketSnapshot?,
            tradeable: WorldMarket.State?
        ) = (
            context.localMarkets[resource / self.tile]?.snapshot(self.region),
            context.worldMarkets[resource / self.region.currency.id]?.state
        )

        switch line.query {
        case .consumed(let id):
            guard let consumed: InventorySnapshot.Consumed = self.inventory[id] else {
                return nil
            }

            if  consumed.tradeable,
                let tradeable: WorldMarket.State = market.tradeable {
                return consumed.tooltipExplainPriceTradeable(market: tradeable)
            } else if
                let segmented: LocalMarketSnapshot = market.segmented {
                return consumed.tooltipExplainPriceSegmented(market: segmented)
            }

        case .produced(let id):
            guard let produced: InventorySnapshot.Produced = self.inventory[id] else {
                return nil
            }

            if  produced.tradeable,
                let tradeable: WorldMarket.State = market.tradeable {
                return produced.tooltipExplainPriceTradeable(market: tradeable)
            } else if
                let segmented: LocalMarketSnapshot = market.segmented {
                return produced.tooltipExplainPriceSegmented(market: segmented)
            }
        }

        return nil
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

    func tooltipOwnership(
        gender: Gender,
        context: GameUI.CacheContext,
    ) -> Tooltip? {
        let (share, total): (share: Int64, total: Int64) = self.equity.owners.reduce(
            into: (0, 0)
        ) {
            if case gender? = $1.gender {
                $0.share += $1.shares
            }

            $0.total += $1.shares
        }

        return .instructions(style: .borderless) {
            $0[gender.singularTabular] = (Double.init(share) / Double.init(total))[%3]
            $0[>] = "\(em: gender.pluralShort) own \(em: share[/3]) shares"
        }
    }

    func tooltipOwnership() -> Tooltip {
        let equity: Equity<LEI>.Snapshot = self.equity
        return .instructions {
            $0["Shares outstanding", (-)] = equity.shareCount[/3] ^^ equity.issued
            $0[>] {
                $0["Today’s trading volume"] = equity.traded[/3]
            }
            if  let splitLast: EquitySplit = equity.splitLast {
                let factor: EquitySplit.Factor = splitLast.factor
                let color: ColorText.Style
                switch factor {
                case .reverse:
                    $0[>] = """
                    This stock most recently underwent \(factor.articleIndefinite) \
                    \(neg: factor) reverse split on \(em: splitLast.date[.phrasal_US])
                    """

                    color = .neg

                case .forward:
                    $0[>] = """
                    This stock most recently underwent \(factor.articleIndefinite) \
                    \(pos: factor) stock split on \(em: splitLast.date[.phrasal_US])
                    """

                    color = .pos
                }

                if  self.equity.splits > 1 {
                    $0[>] = "It has split \(self.equity.splits, style: color) times"
                }
            }
        }
    }
}
