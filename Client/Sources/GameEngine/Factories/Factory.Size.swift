extension Factory {
    struct Size {
        var level: Int64
        var growthProgress: Int

        init(level: Int64, growthProgress: Int = 0) {
            self.level = level
            self.growthProgress = growthProgress
        }
    }
}
extension Factory.Size {
    var value: Int64 {
        self.level * self.level
    }

    static var growthRequired: Int { 100 }

    mutating func grow() {
        if  self.growthProgress < Self.growthRequired - 1 {
            self.growthProgress += 1
        } else {
            self.level += 1
            self.growthProgress = 0
        }
    }
}
#if TESTABLE
extension Factory.Size: Equatable, Hashable {}
#endif
