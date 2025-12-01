import Fraction

protocol BackgroundableMetrics: LegalEntityMetrics {
    var active: Int64 { get set }
    var vacant: Int64 { get set }
}
extension BackgroundableMetrics {
    var total: Int64 { self.active + self.vacant }

    var vacancy: Double {
        self.total > 0 ? Double.init(self.vacant %/ self.total) : 0
    }
}
extension BackgroundableMetrics {
    mutating func restore(vacant: Int64) {
        self.active += vacant
        self.vacant -= vacant
    }
    mutating func background(active: Int64) {
        self.active -= active
        self.vacant += active
    }
}
