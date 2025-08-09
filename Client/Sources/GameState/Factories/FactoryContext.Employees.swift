import GameEngine

extension FactoryContext {
    struct Employees {
        var pops: [(id: GameID<Pop>, count: Int64)]
        var count: Int64
        var xp: Int64

        init() {
            self.pops = []
            self.count = 0
            self.xp = 0
        }
    }
}
