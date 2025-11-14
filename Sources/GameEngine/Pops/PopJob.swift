import Assert
import Random

protocol PopJob<ID>: Identifiable {
    var count: Int64 { get set }
    var hired: Int64 { get set }
    var fired: Int64 { get set }
    var quit: Int64 { get set }
}
extension PopJob {
    mutating func fire(_ layoff: inout PopJobLayoffBlock?) {
        guard
        let size: Int64 = layoff?.size, size > 0 else {
            layoff = nil
            return
        }

        if  size > self.count {
            layoff?.size -= self.count
            self.fireAll()
        } else {
            layoff = nil
            self.fire(size)
        }
    }
}
extension PopJob {
    mutating func fireAll() {
        self.fired += self.count
        self.count = 0
    }

    mutating func fire(_ count: Int64) {
        self.fired += count
        self.count -= count
    }

    mutating func hire(_ count: Int64) {
        self.hired += count
        self.count += count
    }

    mutating func quit(_ count: Int64) {
        self.quit += count
        self.count -= count

        #assert(
            self.count >= 0,
            "Negative employee count (count = \(self.count)) in job \(self.id)!!!"
        )
    }

    mutating func quit(
        rate: Double,
        using generator: inout some RandomNumberGenerator
    ) {
        let quit: Int64 = Binomial[self.count, rate].sample(using: &generator)

        self.quit += quit
        self.count -= quit
    }

    mutating func remove(excess: inout Int64) {
        let quit: Int64 = min(excess, self.count)
        self.quit(quit)
        excess -= quit
    }

    mutating func turn() {
        self.hired = 0
        self.fired = 0
        self.quit = 0
    }
}
