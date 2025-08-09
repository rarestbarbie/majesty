import GameEngine

struct FactoryJobOfferBlock {
    let at: GameID<Factory>
    let bid: Int64
    var size: Int64
}
extension FactoryJobOfferBlock {
    consuming func matched(with workers: inout Int64) -> (size: Int64, remaining: Self?) {
        if  self.size <= workers {
            workers -= self.size
            return (size: self.size, remaining: nil)
        } else {
            self.size -= workers
            defer { workers = 0 }
            return (size: workers, remaining: self)
        }
    }
}
