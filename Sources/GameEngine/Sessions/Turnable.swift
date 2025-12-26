protocol Turnable<Dimensions>: Differentiable {
    var y: Dimensions { get set }
    mutating func turn()
}
extension Turnable {
    mutating func turnToNextDay() {
        self.y = self.z
        self.turn()
    }
}
