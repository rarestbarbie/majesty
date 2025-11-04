extension Mine {
    struct Dimensions {
        var size: Int64
    }
}
extension Mine.Dimensions {
    init() {
        self.init(
            size: 0
        )
    }
}

#if TESTABLE
extension Mine.Dimensions: Equatable, Hashable {}
#endif
