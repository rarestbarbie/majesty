import JavaScriptInterop

extension Mine {
    struct Dimensions {
        var size: Int64
        var yield: Double
        var yieldRank: Int?
        var efficiency: Double
    }
}
extension Mine.Dimensions {
    init() {
        self.init(
            size: 0,
            yield: 0,
            yieldRank: nil,
            efficiency: 0
        )
    }
}
extension Mine.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case size = "size"
        case yield = "yield"
        case yieldRank = "yf"
        case efficiency = "eo"
    }
}
extension Mine.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.size] = self.size
        js[.yield] = self.yield
        js[.yieldRank] = self.yieldRank
        js[.efficiency] = self.efficiency
    }
}
extension Mine.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            size: try js[.size].decode(),
            yield: try js[.yield].decode(),
            yieldRank: try js[.yieldRank]?.decode(),
            efficiency: try js[.efficiency].decode()
        )
    }
}

#if TESTABLE
extension Mine.Dimensions: Equatable {}
#endif
