import ColorText

public protocol ConditionMatrixEncoder<Effect>  {
    associatedtype Effect
    associatedtype ConditionNodes
    associatedtype ConjunctionEncoder: ConditionLogicEncoder<LogicalAll, ConditionNodes>
    associatedtype DisjunctionEncoder: ConditionLogicEncoder<LogicalAny, ConditionNodes>

    mutating func append(
        fulfilled: Bool,
        effect: Effect,
        format: () -> ColorText,
        factors: ConditionNodes?,
    )
}
extension ConditionMatrixEncoder<Void> {
    @inlinable public subscript<Expr>(
        value: Expr.Value,
        yield: (Never?, ConditionParameter) -> Expr
    ) -> (((), Expr.Value) -> ColorText)?
        where Expr: Condition {
        get { nil }
        set(format) {
            guard let format: ((), Expr.Value) -> ColorText else {
                return
            }

            let condition: Expr = yield(nil, .init())
            let predicate: Expr.Value = condition.predicate
            self.append(
                fulfilled: value ~ condition,
                effect: (),
                format: { format((), predicate) },
                factors: nil
            )
        }
    }

    @inlinable public subscript(
        all expected: LogicalAll,
        yield: (inout ConjunctionEncoder) -> ()
    ) -> Void {
        mutating get {
            self[all: expected, then: { $0 = () }, when: yield] = { "\($1)" }
        }
    }

    /// Note that `any: false` renders in the UI as “*Unless all of the following*”, but it does
    /// not exhibit vacuous truth – it will not return true if no conditions are given. Thus,
    /// it would be more precisely described as “*If at least one of the following is not.*”
    @inlinable public subscript(
        any expected: LogicalAny,
        yield: (inout DisjunctionEncoder) -> ()
    ) -> Void {
        mutating get {
            self[any: expected, then: { $0 = () }, when: yield] = { "\($1)" }
        }
    }
}
extension ConditionMatrixEncoder {
    @inlinable public subscript(
        all expected: LogicalAll,
        then effects: (inout Effect?) -> (),
        when clauses: (inout ConjunctionEncoder) -> (),
    ) -> ((Effect, LogicalAll) -> ColorText)? {
        get { nil }
        set(format) {
            guard let format: (Effect, LogicalAll) -> ColorText else {
                return
            }

            var all: ConjunctionEncoder = .init(expected: expected.predicate)
            clauses(&all)

            var effect: Effect? = nil

            effects(&effect)

            guard
            let effect: Effect else {
                return
            }

            self.append(
                fulfilled: all.reduced,
                effect: effect,
                format: { format(effect, expected) },
                factors: all.factors
            )
        }
    }

    @inlinable public subscript(
        any expected: LogicalAny,
        then effects: (inout Effect?) -> (),
        when clauses: (inout DisjunctionEncoder) -> (),
    ) -> ((Effect, LogicalAny) -> ColorText)? {
        get { nil }
        set(format) {
            guard let format: (Effect, LogicalAny) -> ColorText else {
                return
            }

            var any: DisjunctionEncoder = .init(expected: expected.predicate)
            clauses(&any)

            var effect: Effect? = nil

            effects(&effect)

            guard
            let effect: Effect else {
                return
            }

            self.append(
                fulfilled: any.reduced,
                effect: effect,
                format: { format(effect, expected) },
                factors: any.factors
            )
        }
    }

    @inlinable public subscript<Value>(
        value: Value,
        yield: (inout ConditionStack<Effect, Value>, ConditionParameter) -> ()
    ) -> ((Effect, Value) -> ColorText)? {
        get { nil }
        set(format) {
            guard let format: (Effect, Value) -> ColorText else {
                return
            }

            var stack: ConditionStack<Effect, Value> = .init(parameter: value)
            yield(&stack, .init())

            guard
            let bracket: (effect: Effect, value: Value) = stack.bracket else {
                // No conditions were evaluated at all.
                return
            }

            let effect: Effect = stack.effect ?? bracket.effect
            self.append(
                fulfilled: stack.effect != nil,
                effect: effect,
                format: { format(effect, bracket.value) },
                factors: nil
            )
        }
    }

    @inlinable public subscript(
        value: Bool,
        yield: (inout Effect?) -> ()
    ) -> ((Effect) -> ColorText)? {
        get { nil }
        set(format) {
            guard let format: (Effect) -> ColorText else {
                return
            }

            var effect: Effect? = nil
            yield(&effect)

            guard
            let effect: Effect else {
                return
            }

            self.append(
                fulfilled: value,
                effect: effect,
                format: { format(effect) },
                factors: nil
            )
        }
    }
}
