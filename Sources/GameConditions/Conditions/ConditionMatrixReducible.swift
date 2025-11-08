public protocol ConditionMatrixAccumulator<AccumulatorInput> {
    associatedtype AccumulatorInput = Self
    static func += (self: inout Self, next: AccumulatorInput)
}
