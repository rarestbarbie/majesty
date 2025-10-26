import GameIDs

struct Workforce {
    var limit: Int64
    var count: Int64

    var hired: Int64
    var fired: Int64
    var quit: Int64

    var pops: [(id: PopID, count: Int64)]
}
extension Workforce {
    static var empty: Self {
        .init(
            limit: 0,
            count: 0,
            hired: 0,
            fired: 0,
            quit: 0,
            pops: []
        )
    }
}
extension Workforce {
    mutating func count(pop: PopID, job: some PopJob) {
        // self.xp += job.count * Int64.init(job.xp)
        self.count += job.count

        self.hired += job.hired
        self.fired += job.fired
        self.quit += job.quit

        self.pops.append((id: pop, count: job.count))
    }
}
