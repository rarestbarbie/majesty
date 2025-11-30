import Fraction
import GameEconomy
import GameRules
import GameIDs

extension FactoryMetadata {
    func clerkHorizon(for workers: Int64) -> Int64 {
        workers >< (self.clerks.amount %/ self.workers.amount)
    }
    func clerkTarget(for workers: Int64, fk: Double) -> Int64 {
        let optimal: Int64 = self.clerkHorizon(for: workers)
        return .init(fk * Double.init(optimal))
    }
}
