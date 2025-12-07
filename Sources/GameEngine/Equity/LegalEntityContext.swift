import GameEconomy
import GameIDs
import GameState

protocol LegalEntityContext<State>: RuntimeContext where State: LegalEntityState {
    var region: RegionalAuthority? { get }
    var equity: Equity<LEI>.Statistics { get }
}
extension LegalEntityContext {
    var lei: LEI { self.state.id.lei }

    var security: StockMarket.Security {
        .init(
            id: self.lei,
            stockPrice: .init(exact: self.equity.sharePrice),
            profitability: self.state.z.profitability,
        )
    }
}
