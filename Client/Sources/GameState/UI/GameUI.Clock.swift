extension GameUI {
    struct Clock {
        private(set) var speed: GameSpeed
        private(set) var phase: Int

        init(speed: GameSpeed = .init(), phase: Int = 0) {
            self.speed = speed
            self.phase = phase
        }
    }
}
extension GameUI.Clock {
    mutating func faster() {
        self.speed.ticks = max(1, self.speed.ticks - 1)
        self.phase = min(self.phase, self.speed.period - 1)
    }
    mutating func slower() {
        self.speed.ticks = min(5, self.speed.ticks + 1)
        self.phase = min(self.phase, self.speed.period - 1)
    }
    mutating func pause() {
        self.speed.paused.toggle()
        self.phase = 0
    }

    mutating func tick() -> Bool {
        if self.speed.paused {
            return false
        }
        if self.phase == 0 {
            self.phase = self.speed.period - 1
            return true
        } else {
            self.phase -= 1
            return false
        }
    }
}
