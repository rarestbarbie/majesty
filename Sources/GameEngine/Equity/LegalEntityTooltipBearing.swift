import GameEconomy
import GameUI

protocol LegalEntityTooltipBearing: LegalEntityContext {
    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: WorldMarket.State?)
    ) -> Tooltip?
}
extension LegalEntityTooltipBearing {
    func tooltipStockpile(
        _ resource: InventoryLine,
    ) -> Tooltip? {
        guard
        let region: RegionalProperties = self.region?.properties else {
            return nil
        }

        switch resource {
        case .l(let id): return self.state.inventory.l.tooltipStockpile(id, region: region)
        case .e(let id): return self.state.inventory.e.tooltipStockpile(id, region: region)
        case .x(let id): return self.state.inventory.x.tooltipStockpile(id, region: region)
        case .o: return nil
        case .m: return nil
        }
    }
}
