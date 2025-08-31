import Assert

@frozen public struct ResourceOutputs {
    public var tradeable: [TradeableOutput]
    public var inelastic: [InelasticOutput]

    @inlinable public init(tradeable: [TradeableOutput], inelastic: [InelasticOutput]) {
        self.tradeable = tradeable
        self.inelastic = inelastic
    }

    @inlinable public init() {
        self.tradeable = []
        self.inelastic = []
    }
}
extension ResourceOutputs {
    @inlinable public var count: Int { self.tradeable.count + self.inelastic.count }
}
extension ResourceOutputs {
    /// Returns the amount of funds actually received.
    public mutating func sell(
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        self.tradeable.indices.reduce(into: 0) {
            $0 += self.tradeable[$1].sell(in: currency, on: &exchange)
        }
    }
}

#if TESTABLE
extension ResourceOutputs: Equatable, Hashable {}
#endif
