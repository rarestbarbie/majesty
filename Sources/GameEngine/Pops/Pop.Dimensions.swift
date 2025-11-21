import JavaScriptKit
import JavaScriptInterop

extension Pop {
    struct Dimensions: LegalEntityMetrics {
        var size: Int64
        var mil: Double
        var con: Double
        var fl: Double
        var fe: Double
        var fx: Double
        var vl: Int64
        var ve: Int64
        var vx: Int64
        var px: Double
        /// A number between -1 and 1.
        var profitability: Double
    }
}
extension Pop.Dimensions {
    init() {
        self.init(size: 0, mil: 0, con: 0, fl: 0, fe: 0, fx: 0, vl: 0, ve: 0, vx: 0, px: 1, profitability: 0)
    }
}
extension Pop.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case size = "size"
        case mil = "mil"
        case con = "con"
        case fl = "fl"
        case fe = "fe"
        case fx = "fx"
        case vl = "vl"
        case ve = "ve"
        case vx = "vx"
        case px = "px"
        case profitability = "pa"
    }
}
extension Pop.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.size] = self.size
        js[.mil] = self.mil
        js[.con] = self.con
        js[.fl] = self.fl
        js[.fe] = self.fe
        js[.fx] = self.fx
        js[.vl] = self.vl
        js[.ve] = self.ve
        js[.vx] = self.vx
        js[.px] = self.px
        js[.profitability] = self.profitability
    }
}
extension Pop.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            size: try js[.size].decode(),
            mil: try js[.mil]?.decode() ?? 0,
            con: try js[.con]?.decode() ?? 0,
            fl: try js[.fl]?.decode() ?? 0,
            fe: try js[.fe]?.decode() ?? 0,
            fx: try js[.fx]?.decode() ?? 0,
            vl: try js[.vl]?.decode() ?? 0,
            ve: try js[.ve]?.decode() ?? 0,
            vx: try js[.vx]?.decode() ?? 0,
            px: try js[.px]?.decode() ?? 1,
            profitability: try js[.profitability]?.decode() ?? 0,
        )
    }
}

#if TESTABLE
extension Pop.Dimensions: Equatable, Hashable {}
#endif
