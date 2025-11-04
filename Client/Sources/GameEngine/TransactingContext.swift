import GameState

protocol TransactingContext: RuntimeContext where State: Turnable {
    mutating func allocate(map: inout GameMap)
    mutating func transact(map: inout GameMap)
}
extension TransactingContext where State: Turnable {
    mutating func turn(on map: inout GameMap) {
        self.state.turnToNextDay()
        self.allocate(map: &map)
    }
}
