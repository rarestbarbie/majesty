import Fraction
import GameEconomy
import GameRules
import GameIDs

extension FactoryContext {
    struct ClerkBonus {
        let ratio: Fraction
    }
}
extension FactoryContext.ClerkBonus {
    func optimal(for workers: Int64) -> Int64 {
        workers >< self.ratio
    }
}
