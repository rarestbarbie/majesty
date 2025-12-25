import GameEconomy
import GameIDs
import GameState
import Random

protocol LegalEntityContext<State>: RuntimeContext where State: LegalEntityState {
    var region: RegionalAuthority? { get }
    var equity: Equity<LEI>.Statistics { get }

    static var stockpileDaysRange: ClosedRange<Int64> { get }
}
extension LegalEntityContext {
    static var stockpileDaysMax: Int64 {
        ResourceInputs.stockpileDaysFactor * Self.stockpileDaysRange.upperBound
    }

    func stockpileTarget(_ random: inout PseudoRandom) -> ResourceStockpileTarget {
        .random(in: Self.stockpileDaysRange, using: &random)
    }

    var lei: LEI { self.state.id.lei }

    var security: StockMarket.Security {
        .init(
            id: self.lei,
            stockPrice: .init(exact: self.equity.sharePrice),
            profitability: self.state.z.profitability,
        )
    }
}
