protocol Turnable<Dimensions> {
    associatedtype Dimensions

    /// **Y**esterday’s state.
    var y: Dimensions { get set }
    /// Today’s state, which might be indeterminate until the turn is processed.
    var z: Dimensions { get }

    mutating func turn()
}
extension Turnable {
    var Δ: TurnDelta<Dimensions> { .init(y: self.y, z: self.z) }
}
extension Turnable {
    mutating func turnToNextDay() {
        self.y = self.z
        self.turn()
    }
}
