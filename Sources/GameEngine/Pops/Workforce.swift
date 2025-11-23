import D
import GameIDs
import GameUI

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
    var change: Int64 { self.hired - self.fired - self.quit }
    var before: Int64 { self.count - self.change }
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
extension Workforce {
    func explainChanges(_ ul: inout TooltipInstructionEncoder) {
        if  self.change == 0, self.hired == 0, self.fired == 0, self.quit == 0 {
            return
        }
        // we never want to elide this, but still show one of the sub-items, that wouldn’t
        // make any sense
        ul["Today’s change", +] = +self.change[/3]
        ul[>] {
            $0["Hired", +] = +?self.hired[/3]
            $0["Fired", +] = ??(-self.fired)[/3]
            $0["Quit", +] = ??(-self.quit)[/3]
        }
    }
}
