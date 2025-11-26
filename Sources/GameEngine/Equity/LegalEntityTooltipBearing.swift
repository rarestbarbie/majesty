import GameEconomy
import GameUI

protocol LegalEntityTooltipBearing: LegalEntityContext {
    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: BlocMarket.State?)
    ) -> Tooltip?
}
