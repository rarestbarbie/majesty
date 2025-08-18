import ColorText

extension ConditionEvaluator {
    @frozen public struct MatrixEncoder<T> where T: ConditionMatrixAccumulator {
        @usableFromInline var reduced: T

        @inlinable init(base: T) {
            self.reduced = base
        }
    }
}
extension ConditionEvaluator.MatrixEncoder: ConditionMatrixEncoder {
    public typealias ConditionNodes = Never
    public typealias ConjunctionEncoder = ConditionEvaluator.LogicalEncoder<LogicalAll>
    public typealias DisjunctionEncoder = ConditionEvaluator.LogicalEncoder<LogicalAny>

    @inlinable public mutating func append(
        fulfilled: Bool,
        effect: T.AccumulatorInput,
        format _: () -> ColorText,
        factors _: Never?
    ) {
        fulfilled ? self.reduced += effect : ()
    }
}
