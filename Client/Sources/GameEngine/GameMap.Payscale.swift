import GameState

extension GameMap {
    struct Payscale {
        let pops: [(id: GameID<Pop>, count: Int64)]
        let rate: Int64
    }
}
extension GameMap.Payscale: RandomAccessCollection {
    var startIndex: Int { self.pops.startIndex }
    var endIndex: Int { self.pops.endIndex }

    subscript(position: Int) -> (id: GameID<Pop>, owed: Int64) {
        let (id, size): (GameID<Pop>, Int64) = self.pops[position]
        return (id: id, owed: size * self.rate)
    }
}
