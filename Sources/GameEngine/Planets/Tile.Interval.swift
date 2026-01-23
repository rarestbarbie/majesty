extension Tile {
    struct Interval {
        var stats: Stats
        var state: Dimensions
    }
}
#if TESTABLE
extension Tile.Interval: Equatable {}
#endif
