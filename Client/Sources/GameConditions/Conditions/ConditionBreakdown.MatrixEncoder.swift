import ColorText

extension ConditionBreakdown {
    @frozen public struct MatrixEncoder<T> where T: ConditionMatrixAccumulator {
        @usableFromInline var factors: [Node]
        @usableFromInline var reduced: T

        @inlinable init(base: T) {
            self.factors = []
            self.reduced = base
        }
    }
}
extension ConditionBreakdown.MatrixEncoder: ConditionMatrixEncoder {
    public typealias ConditionNodes = [ConditionBreakdown.Node]
    public typealias ConjunctionEncoder = ConditionBreakdown.LogicalEncoder<LogicalAll>
    public typealias DisjunctionEncoder = ConditionBreakdown.LogicalEncoder<LogicalAny>

    @inlinable public mutating func append(
        fulfilled: Bool,
        effect: T.AccumulatorInput,
        format: () -> ColorText,
        factors: [ConditionBreakdown.Node]?
    ) {
        fulfilled ? self.reduced += effect : ()

        let node: ConditionBreakdown.Node = .init(
            listItem: .init(fulfilled: fulfilled, highlight: true, description: format()),
            children: factors ?? []
        )

        self.factors.append(node)
    }
}
