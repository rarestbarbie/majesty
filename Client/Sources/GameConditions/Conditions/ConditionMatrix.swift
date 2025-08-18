public protocol ConditionMatrix<Effect, Output> {
    associatedtype Effect
    associatedtype Output
    associatedtype AddendsEncoder: ConditionMatrixEncoder<Effect>
    associatedtype FactorsEncoder: ConditionMatrixEncoder<Effect>

    init(
        base: Effect,
        addends: borrowing (inout AddendsEncoder) -> (),
        factors: borrowing (inout FactorsEncoder) -> ()
    )
    var output: Output { get }
}
