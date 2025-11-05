@frozen public struct GameSpeed {
    public var paused: Bool
    public var ticks: Int

    @inlinable public init(paused: Bool = true, ticks: Int = 3) {
        self.paused = paused
        self.ticks = ticks
    }
}
extension GameSpeed {
    @inlinable var period: Int {
        switch self.ticks {
        case 1: return 1
        case 2: return 2
        case 3: return 4
        case 4: return 8
        case _: return 12
        }
    }
}
