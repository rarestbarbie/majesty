import Fraction
import GameIDs

protocol LegalEntityState<Dimensions>: Turnable, Identifiable
    where Dimensions: LegalEntityMetrics, Self.ID: LegalEntityIdentifier {
    var inventory: Inventory { get }
    var equity: Equity<LEI> { get }
}
extension LegalEntityState {
    var grossProfit: Int64 {
        self.Δ.vi.value + // Change in stockpiled inputs
        self.inventory.account.b + // Spending on inputs
        self.inventory.account.w + // Spending on wages
        self.inventory.account.r // Revenue
    }
    var grossMargin: Fraction? {
        self.inventory.account.r > 0 ? self.grossProfit %/ self.inventory.account.r : nil
    }

    var operatingProfit: Int64 {
        self.grossProfit + self.inventory.account.c
    }
    var operatingMargin: Fraction? {
        self.inventory.account.r > 0 ? self.operatingProfit %/ self.inventory.account.r : nil
    }
}
