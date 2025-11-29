import Fraction
import GameEconomy
import GameRules
import GameIDs

extension FactoryMetadata {
    var clerkBonus: FactoryContext.ClerkBonus {
        .init(ratio: self.clerks.amount %/ self.workers.amount)
    }
}
