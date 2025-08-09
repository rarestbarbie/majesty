@frozen public struct ConditionEvaluator {
    public let output: Double

    public init(output: Double) {
        self.output = output
    }
}
extension ConditionEvaluator: ConditionMatrix {
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
            output: factorsEncoder.reduced.raise(scaling: addendsEncoder.reduced),
        )
    }
}
