import Fraction
import GameEconomy
import GameRules
import GameIDs

extension FactoryMetadata {
    var clerkBonus: ClerkBonus? {
        guard
        let clerks: Quantity<PopType> = self.clerks else {
            return nil
        }
        return .init(ratio: clerks.amount %/ self.workers.amount, type: clerks.unit)
    }
}
