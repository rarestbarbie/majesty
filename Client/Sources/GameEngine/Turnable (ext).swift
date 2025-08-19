import GameState

extension Turnable {
    var Δ: TurnDelta<Dimensions> {
        .init(yesterday: self.yesterday, today: self.today)
    }
}
