import GameIDs

extension GameMap {
    struct Payscale {
        let pops: [(id: PopID, count: Int64)]
        let rate: Int64
    }
}
extension GameMap.Payscale: RandomAccessCollection {
    var startIndex: Int { self.pops.startIndex }
    var endIndex: Int { self.pops.endIndex }

    subscript(position: Int) -> (id: PopID, owed: Int64) {
        let (id, size): (PopID, Int64) = self.pops[position]
        return (id: id, owed: size * self.rate)
    }
}
