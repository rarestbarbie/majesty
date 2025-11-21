import RealModule

protocol LegalEntityMetrics {
    var px: Double { get }
    var profitability: Double { get set }
}
extension LegalEntityMetrics {
    mutating func mix(profitability: Double, rate: Double = 0.05) {
        self.profitability = max(-1, min(rate.mix(self.profitability, profitability), 1))
    }
}
