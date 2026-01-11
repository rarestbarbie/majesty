import Fraction
import Random

protocol Differentiable<Dimensions> {
    associatedtype Dimensions

    /// **Y**esterday’s state.
    var y: Dimensions { get }
    /// Today’s state, which might be indeterminate until the turn is processed.
    var z: Dimensions { get }
}
extension Differentiable {
    var Δ: Delta<Dimensions> { .init(y: self.y, z: self.z) }
}

// i don’t think this is a good file to host these extensions, but i can’t think of a less
// awkward place for the API to be callable from
extension Differentiable where Dimensions: BackgroundableMetrics {
    var restoration: Double? {
        guard self.z.fe > Dimensions.vertex else {
            return nil
        }
        let parameter: Double = self.z.fe - Dimensions.vertex
        return Dimensions.restoration * parameter
    }
    var attrition: Double? {
        guard self.z.fe < Dimensions.vertex else {
            return nil
        }
        let parameter: Double = Dimensions.vertex - self.z.fe
        return Dimensions.attrition * parameter
    }
}
extension Differentiable where Dimensions: BackgroundableMetrics {
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
        base: Double,
        random: inout PseudoRandom
    ) -> Int64? {
        let recallable: Int64 = self.z.active - 1
        if  recallable <= 0 {
            return nil
        }

        // operational needs not being met
        let deficit: Double = self.z.fl - 1
        /// a number between -1 and 0, if backgrounding should occur
        let scale: Double = min(base, deficit)
        if  scale >= 0 {
            return nil
        }

        let p: Double = max(-1, scale) * Dimensions.mothballing
        let mothball: Int64 = Binomial[recallable, p].sample(using: &random.generator)

        return mothball > 0 ? mothball : nil
    }
}
