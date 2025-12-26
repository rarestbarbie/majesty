import GameState

protocol AllocatingContext: ~Copyable, RuntimeContext where State: Turnable {
    mutating func allocate(turn: inout Turn)
}
extension AllocatingContext where Self: ~Copyable, State: Turnable {
    mutating func turn(on turn: inout Turn) {
        self.state.turnToNextDay()
        self.allocate(turn: &turn)
    }
}
