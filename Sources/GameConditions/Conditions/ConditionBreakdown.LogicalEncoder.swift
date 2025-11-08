import ColorText

extension ConditionBreakdown {
    @frozen public struct LogicalEncoder<Reduction> where Reduction: LogicalReduction {
        @usableFromInline let expected: Bool
        @usableFromInline var _reduced: Bool
        @usableFromInline var nodes: [Node]

        @inlinable public init(expected: Bool) {
            self.expected = expected
            self._reduced = Reduction.identity
            self.nodes = []
        }
    }
}
extension ConditionBreakdown.LogicalEncoder: ConditionLogicEncoder {
    public typealias ConditionNodes = [ConditionBreakdown.Node]
    public typealias ConjunctionEncoder = ConditionBreakdown.LogicalEncoder<LogicalAll>
    public typealias DisjunctionEncoder = ConditionBreakdown.LogicalEncoder<LogicalAny>

    @inlinable public var reduced: Bool { self._reduced }
    @inlinable public var factors: [ConditionBreakdown.Node]? { self.nodes }

    @inlinable public mutating func append(
        fulfilled: Bool,
        effect: (),
        format: () -> ColorText,
        factors: [ConditionBreakdown.Node]?
    ) {
        let highlight: Bool

        if case Reduction.identity = fulfilled == self.expected {
            highlight = false
        } else {
            highlight = true
            self._reduced = !Reduction.identity
        }

        let node: ConditionBreakdown.Node = .init(
            listItem: .init(fulfilled: fulfilled, highlight: highlight, description: format()),
            children: factors ?? []
        )

        self.nodes.append(node)
    }
}
