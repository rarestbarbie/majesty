import D

@frozen public struct ConditionBreakdown {
    public let base: Decimal
    public let addends: [Node]
    public let factors: [Node]
    public let output: Double

    public init(
        base: Decimal,
        addends: [Node] = [],
        factors: [Node] = [],
        output: Double
    ) {
        self.base = base
        self.addends = addends
        self.factors = factors
        self.output = output
    }
}
extension ConditionBreakdown: ConditionMatrix {
    public init(
        base: Decimal,
        addends: borrowing (inout MatrixEncoder<Decimal>) -> (),
        factors: borrowing (inout MatrixEncoder<DecimalLog>) -> ()
    ) {
        var addendsEncoder: MatrixEncoder<Decimal> = .init(base: base)
        addends(&addendsEncoder)

        var factorsEncoder: MatrixEncoder<DecimalLog> = .init(base: .init())
        factors(&factorsEncoder)

        self.init(
            base: base,
            addends: addendsEncoder.factors,
            factors: factorsEncoder.factors,
            output: factorsEncoder.reduced.raise(scaling: addendsEncoder.reduced),
        )
    }
}
