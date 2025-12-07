import D

extension CountryModifiers {
    struct Stack<Value> {
        var value: Value
        var blame: [(Value, EffectProvenance)]

        init(value: Value, blame: [(Value, EffectProvenance)] = []) {
            self.value = value
            self.blame = blame
        }
    }
}
extension CountryModifiers.Stack: Sendable where Value: Sendable {}
extension CountryModifiers.Stack where Value: AdditiveArithmetic {
    static var zero: Self { .init(value: .zero) }
}
extension CountryModifiers.Stack<Int64>{
    mutating func stack(with next: Int64, from source: EffectProvenance) {
        self.value += next
        self.blame.append((next, source))
    }
}
extension CountryModifiers.Stack<Decimal> {
    mutating func stack(with next: Decimal, from source: EffectProvenance) {
        self.value += next
        self.blame.append((next, source))
    }
}
