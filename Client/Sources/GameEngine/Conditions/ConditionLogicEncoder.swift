public protocol ConditionLogicEncoder<Reduction, ConditionNodes>: ConditionMatrixEncoder<Void> {
    associatedtype Reduction: LogicalReduction
    init(expected: Bool)
    var reduced: Bool { get }
    var factors: ConditionNodes? { get }
}
