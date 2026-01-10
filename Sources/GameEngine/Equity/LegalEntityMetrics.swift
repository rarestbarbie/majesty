import D
import Random
import RealModule

protocol LegalEntityMetrics {
    var fl: Double { get }
    var fe: Double { get }

    var vl: Int64 { get }
    var ve: Int64 { get }
    var vx: Int64 { get }
    var vout: Int64 { get }

    var px: Double { get }
    var profitability: Double { get set }
}
extension LegalEntityMetrics {
    var vv: Int64 { self.vl + self.ve + self.vout }
    var assets: Int64 { self.vl + self.ve + self.vx + self.vout }
}
extension LegalEntityMetrics {
    mutating func mix(profitability: Double, rate: Double = 0.05) {
        self.profitability = max(-1, min(rate.mix(self.profitability, profitability), 1))
    }
}
