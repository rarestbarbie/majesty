import ColorText

extension ConditionEvaluator {
    @frozen public struct LogicalEncoder<Reduction> where Reduction: LogicalReduction {
        @usableFromInline let expected: Bool
        @usableFromInline var _reduced: Bool

        @inlinable public init(expected: Bool) {
            self.expected = expected
            self._reduced = Reduction.identity
        }
    }
}
extension ConditionEvaluator.LogicalEncoder: ConditionLogicEncoder {
    public typealias ConditionNodes = Never
    public typealias ConjunctionEncoder = ConditionEvaluator.LogicalEncoder<LogicalAll>
    public typealias DisjunctionEncoder = ConditionEvaluator.LogicalEncoder<LogicalAny>

    @inlinable public var reduced: Bool { self._reduced }
    @inlinable public var factors: Never? { nil }

    @inlinable public mutating func append(
        fulfilled: Bool,
        effect _: (),
        format _: () -> ColorText,
        factors _: Never?
    ) {
        if case Reduction.identity = fulfilled == self.expected {
        } else {
            self._reduced = !Reduction.identity
        }
    }
}
