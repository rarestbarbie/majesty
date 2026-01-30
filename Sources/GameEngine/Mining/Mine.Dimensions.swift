import JavaScriptInterop

extension Mine {
    struct Dimensions {
        var size: Int64
        /// if we wish to know yesterday’s yield, we must know yesterday’s parcels, not today’s
        /// parcels.
        var splits: Int
        var yieldBase: Double
        var yieldRank: Int?
        var efficiency: Double
    }
}
extension Mine.Dimensions {
    var parcels: Int64 {
        1 << self.splits
    }

    var parcelFraction: Double {
        Double.init(sign: .plus, exponent: -self.splits, significand: 1)
    }

    var efficiencyPerMiner: Double {
        self.efficiency * self.parcelFraction
    }

    var yieldPerMiner: Double {
        self.parcelFraction * self.yieldBase
    }
}
extension Mine.Dimensions {
    init() {
        self.init(
            size: 0,
            splits: 0,
            yieldBase: 0,
            yieldRank: nil,
            efficiency: 0
        )
    }
}
extension Mine.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case size = "size"
        case splits = "e"
        case yieldBase = "yield"
        case yieldRank = "yf"
        case efficiency = "eo"
    }
}
extension Mine.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.size] = self.size
        js[.splits] = self.splits != 0 ? self.splits : nil
        js[.yieldBase] = self.yieldBase
        js[.yieldRank] = self.yieldRank
        js[.efficiency] = self.efficiency
    }
}
extension Mine.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            size: try js[.size].decode(),
            splits: try js[.splits]?.decode() ?? 0,
            yieldBase: try js[.yieldBase].decode(),
            yieldRank: try js[.yieldRank]?.decode(),
            efficiency: try js[.efficiency].decode()
        )
    }
}

#if TESTABLE
extension Mine.Dimensions: Equatable {}
#endif
