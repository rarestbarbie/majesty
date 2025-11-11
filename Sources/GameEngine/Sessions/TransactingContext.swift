import GameState

protocol TransactingContext: RuntimeContext where State: Turnable {
    mutating func allocate(turn: inout Turn)
    mutating func transact(turn: inout Turn)
}
extension TransactingContext where State: Turnable {
    mutating func turn(on turn: inout Turn) {
        self.state.turnToNextDay()
        self.allocate(turn: &turn)
    }
}
