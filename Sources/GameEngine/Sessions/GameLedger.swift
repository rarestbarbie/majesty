struct GameLedger: Differentiable {
    var y: Interval
    var z: Interval
}
extension GameLedger {
    init() {
        self.init(
            y: .init(),
            z: .init()
        )
    }
}
