import D
import Random
import RealModule

protocol LegalEntityMetrics {
    var fl: Double { get }
    var fe: Double { get }

    var vl: Int64 { get }
    var ve: Int64 { get }

    var px: Double { get }
    var profitability: Double { get set }
}
extension LegalEntityMetrics {
    mutating func mix(profitability: Double, rate: Double = 0.05) {
        self.profitability = max(-1, min(rate.mix(self.profitability, profitability), 1))
    }
}
extension LegalEntityMetrics {
    func mothball(
        active: Int64,
        utilization: Double,
        utilizationThreshold: Double = 0.95,
        rate: @autoclosure () -> Double,
        random: inout PseudoRandom
    ) -> Int64? {
        let recallable: Int64 = active - 1
        if  recallable <= 0 {
            return nil
        }

        /// a number between -1 and 0, if backgrounding should occur
        let excess: Double = min(
            // utilization of active units is below threshold
            utilization - utilizationThreshold,
            // operational needs not being met
            self.fl - 1,
            // self-explanatory
            self.profitability
        )
        if  excess >= 0 {
            return nil
        }

        let mothball: Int64 = Binomial[recallable, -excess * rate()].sample(
            using: &random.generator
        )

        return mothball > 0 ? mothball : nil
    }
}
