@frozen public struct ConditionStack<Effect, Value>  {
    @usableFromInline let parameter: Value
    @usableFromInline var bracket: (Effect, Value)?
    @usableFromInline var effect: Effect?

    @inlinable init(parameter: Value, bracket: (Effect, Value)? = nil, effect: Effect? = nil) {
        self.parameter = parameter
        self.bracket = bracket
        self.effect = effect
    }
}
extension ConditionStack where Value: LogicalReduction {
    @inlinable public subscript(condition: Value) -> Effect? {
        get { nil }
        set(effect) {
            guard let effect: Effect else {
                return
            }

            if  self.parameter == condition {
                self.bracket = (effect, condition)
                self.effect = effect
            } else if case nil = self.bracket {
                self.bracket = (effect, condition)
            }
        }
    }
}
extension ConditionStack where Effect == Decimal {
    @inlinable public subscript(condition: some Condition<Value>) -> Decimal? {
        get { nil }
        set(effect) {
            guard let effect: Decimal else {
                return
            }

            if  self.parameter ~ condition {
                self.bracket = (effect, condition.predicate)
                self.effect = self.effect.map { $0 + effect } ?? effect
            } else if case nil = self.bracket {
                self.bracket = (effect, condition.predicate)
            }
        }
    }
}
