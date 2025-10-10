import GameIDs

extension FactoryContext {
    struct Employees {
        var pops: [(id: PopID, count: Int64)]
        var count: Int64
        var xp: Int64

        init() {
            self.pops = []
            self.count = 0
            self.xp = 0
        }
    }
}
