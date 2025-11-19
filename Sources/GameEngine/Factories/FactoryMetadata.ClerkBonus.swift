import Fraction
import GameEconomy
import GameRules
import GameIDs

extension FactoryMetadata {
    struct ClerkBonus {
        let ratio: Fraction
        let type: PopType
    }
}
extension FactoryMetadata.ClerkBonus {
    func optimal(for workers: Int64) -> Int64 {
        workers >< self.ratio
    }
}
