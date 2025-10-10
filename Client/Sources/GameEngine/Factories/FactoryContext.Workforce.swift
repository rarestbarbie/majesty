import GameIDs

extension FactoryContext {
    struct Workforce {
        var limit: Int64
        var count: Int64

        var hired: Int64
        var fired: Int64
        var quit: Int64

        var pops: [(id: PopID, count: Int64)]
        var xp: Int64

        init() {
            self.limit = 0
            self.count = 0

            self.hired = 0
            self.fired = 0
            self.quit = 0

            self.pops = []
            self.xp = 0
        }
    }
}
extension FactoryContext.Workforce {
    mutating func count(pop: PopID, job: FactoryJob) {
        self.xp += job.count * Int64.init(job.xp)
        self.count += job.count

        self.hired += job.hired
        self.fired += job.fired
        self.quit += job.quit


        self.pops.append((id: pop, count: job.count))
    }
}
