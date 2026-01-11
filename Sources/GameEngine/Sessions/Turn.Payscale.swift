import GameIDs
import Random

extension Turn {
    struct Payscale {
        let pops: [(id: PopID, count: Int64)]
        let rate: Int64
    }
}
extension Turn.Payscale {
    static func shuffle(
        pops: [(id: PopID, count: Int64)],
        rate: Int64,
        using random: inout PseudoRandom,
    ) -> Self {
        .init(pops: pops.shuffled(using: &random.generator), rate: rate)
    }
}
extension Turn.Payscale: RandomAccessCollection {
    var startIndex: Int { self.pops.startIndex }
    var endIndex: Int { self.pops.endIndex }

    subscript(position: Int) -> (id: PopID, owed: Int64) {
        let (id, size): (PopID, Int64) = self.pops[position]
        return (id: id, owed: size * self.rate)
    }
}
