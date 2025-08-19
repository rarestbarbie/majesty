import GameState

extension FactoryContext {
    struct Workforce {
        var limit: Int64
        var n: Employees
        var u: Employees
        var s: Employees

        var hire: Int64
        var fire: Int64
        var quit: Int64

        init() {
            self.limit = 0
            self.n = .init()
            self.u = .init()
            self.s = .init()

            self.hire = 0
            self.fire = 0
            self.quit = 0
        }
    }
}
extension FactoryContext.Workforce {
    var present: Int64 { self.n.count + self.u.count }

    /// Total number of workers, including those on strike.
    var total: Int64 { self.n.count + self.u.count + self.s.count }

    mutating func count(pop: PopID, job: FactoryJob) {
        self.hire += job.hire
        self.fire += job.fire
        self.quit += job.quit

        if job.u > 0 {
            if job.strike {
                self.s.pops.append((pop, job.u))
                self.s.count += job.u
                return
            }
            self.u.pops.append((pop, job.u))
            self.u.count += job.u
            self.u.xp += job.u * Int64.init(job.ux)
        }
        if job.n > 0 {
            self.n.pops.append((pop, job.n))
            self.n.count += job.n
            self.n.xp += job.n * Int64.init(job.nx)
        }
    }
}
