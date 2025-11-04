protocol Turnable<Dimensions> {
    associatedtype Dimensions

    var yesterday: Dimensions { get set }
    var today: Dimensions { get }

    mutating func turn()
}
extension Turnable {
    var Δ: TurnDelta<Dimensions> {
        .init(yesterday: self.yesterday, today: self.today)
    }
}
extension Turnable {
    mutating func turnToNextDay() {
        self.yesterday = self.today
        self.turn()
    }
}
