import GameState

protocol TransactingContext: RuntimeContext where State: Turnable {
    mutating func allocate(on map: inout GameMap)
    mutating func transact(on map: inout GameMap)
}
extension TransactingContext where State: Turnable {
    mutating func turn(on map: inout GameMap) {
        { $0.yesterday = $0.today ; $0.turn() } (&self.state) ; self.allocate(on: &map)
    }
}
