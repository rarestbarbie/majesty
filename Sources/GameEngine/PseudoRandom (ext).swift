import JavaScriptInterop
import Random

extension PseudoRandom: LoadableFromJSValue,
    @retroactive ConstructibleFromJSValue,
    @retroactive ConvertibleToJSValue {
}
extension PseudoRandom {
    /// Interpolates the probability of obtaining a successful outcome between the range of
    /// `gate`. The probability is 0 if `n` is less than or equal to the lower bound of `gate`,
    /// and rises linearly to 1 as `n` approaches the upper bound of `gate`.
    @inlinable public mutating func wait(_ n: Int64, _ gate: ClosedRange<Int64>) -> Bool {
        guard n > gate.lowerBound else {
            return false
        }
        guard n < gate.upperBound else {
            return true
        }

        return self.roll(n - gate.lowerBound, gate.upperBound - gate.lowerBound)
    }
}
