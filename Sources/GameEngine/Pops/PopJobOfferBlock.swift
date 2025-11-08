import GameIDs

struct PopJobOfferBlock {
    let job: PopJobOffer
    let bid: Int64
    var size: Int64
}
extension PopJobOfferBlock {
    consuming func matched(with workers: inout Int64) -> (count: Int64, remaining: Self?) {
        if  self.size <= workers {
            workers -= self.size
            return (count: self.size, remaining: nil)
        } else {
            self.size -= workers
            defer { workers = 0 }
            return (count: workers, remaining: self)
        }
    }
}
