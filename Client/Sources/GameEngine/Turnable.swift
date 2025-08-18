protocol Turnable<Dimensions> {
    associatedtype Dimensions

    var yesterday: Dimensions { get set }
    var today: Dimensions { get }

    mutating func turn()
}
extension Turnable {
    mutating func turn() {}

    var Δ: TurnDelta<Dimensions> {
        .init(yesterday: self.yesterday, today: self.today)
    }
}
