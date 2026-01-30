extension EconomicLedger {
    protocol SocialMetricsAggregatable: MeanAggregatable {
        var count: Int64 { get }
        var mil: Double { get }
        var con: Double { get }
    }
}
extension EconomicLedger.SocialMetricsAggregatable {
    var social: EconomicLedger.SocialMetrics {
        .init(
            count: self.count,
            mil: self.mil,
            con: self.con
        )
    }

    var weighted: Self { self }
    var weight: Double { Double.init(self.count) }
}
