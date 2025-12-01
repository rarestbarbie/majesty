import Fraction
import Random

protocol Backgroundable: LegalEntityState where Dimensions: BackgroundableMetrics {
    static var mothballing: Double { get }
    static var restoration: Double { get }
    static var attrition: Double { get }
    static var vertex: Double { get }
}
extension Backgroundable {
    var restoration: Double? {
        guard self.z.fe > Self.vertex else {
            return nil
        }
        let parameter: Double = self.z.fe - Self.vertex
        return Self.restoration * parameter
    }
    var attrition: Double? {
        guard self.z.fe < Self.vertex else {
            return nil
        }
        let parameter: Double = Self.vertex - self.z.fe
        return Self.attrition * parameter
    }
}
extension Backgroundable {
    var profit: ProfitMargins {
        /// this is the minimum fraction of `fe` we would require if we only paid maintenance
        /// for active facilities
        let expected: Double = Double.init(self.z.active) / Double.init(self.z.total)
        let prorate: Double = max(0, self.z.fe - expected)

        let fixedCosts: Int64 = self.inventory.e.valueConsumed
        /// this is a reasonable underestimate of the amount of maintenance costs that went
        /// towards maintaining vacant facilities
        let carryingCosts: Int64 = Int64.init(Double.init(fixedCosts) * prorate)
        return .init(
            materialsCosts: self.inventory.l.valueConsumed,
            operatingCosts: fixedCosts - carryingCosts,
            carryingCosts: carryingCosts,
            revenue: self.inventory.out.valueSold
        )
    }
}
extension Backgroundable {
    var developmentRateVacancyFactor: Double {
        guard self.z.active > self.z.vacant else {
            return 0
        }
        return Double.init((self.z.active - self.z.vacant) %/ (self.z.active + self.z.vacant))
    }

    func developmentRate(
        utilization: Double
    ) -> Double {
        guard self.z.profitability > 0 else {
            return 0
        }
        return self.z.profitability * self.developmentRateVacancyFactor * utilization
    }

    func backgroundable(
        base: Double = 0,
        random: inout PseudoRandom
    ) -> Int64? {
        let recallable: Int64 = self.z.active - 1
        if  recallable <= 0 {
            return nil
        }

        /// a number between -1 and 0, if backgrounding should occur
        let scale: Double = min(
            // utilization of active units is below threshold
            base,
            // operational needs not being met
            self.z.fl - 1,
            // self-explanatory
            self.z.profitability
        )
        if  scale >= 0 {
            return nil
        }

        let mothball: Int64 = Binomial[recallable, scale * Self.mothballing].sample(
            using: &random.generator
        )

        return mothball > 0 ? mothball : nil
    }
}
