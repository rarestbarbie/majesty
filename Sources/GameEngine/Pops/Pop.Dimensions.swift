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
        var px: Double
        /// Investor confidence, a number between 0 and 1.
        var pa: Double
        var vi: Int64
    }
}
extension Pop.Dimensions {
    init() {
        self.init(size: 0, mil: 0, con: 0, fl: 0, fe: 0, fx: 0, px: 1, pa: 0.5, vi: 0)
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
        case px = "px"
        case pa = "pa"
        case vi = "vi"
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
        js[.px] = self.px
        js[.pa] = self.pa
        js[.vi] = self.vi
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
            px: try js[.px]?.decode() ?? 1,
            pa: try js[.pa]?.decode() ?? 0.5,
            vi: try js[.vi]?.decode() ?? 0
        )
    }
}

#if TESTABLE
extension Pop.Dimensions: Equatable, Hashable {}
#endif
