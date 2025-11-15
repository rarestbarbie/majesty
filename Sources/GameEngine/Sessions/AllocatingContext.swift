import GameState

protocol AllocatingContext: RuntimeContext where State: Turnable {
    mutating func allocate(turn: inout Turn)
}
extension AllocatingContext where State: Turnable {
    mutating func turn(on turn: inout Turn) {
        self.state.turnToNextDay()
        self.allocate(turn: &turn)
    }
}
