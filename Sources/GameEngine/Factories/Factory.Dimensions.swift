import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension Factory {
    struct Dimensions: LegalEntityMetrics {
        var vl: Int64
        var ve: Int64
        var vx: Int64

        /// Worker raise probability, set if the factory couldn’t hire any workers.
        ///
        /// The probability is 1 when this value equals ``FactoryContext.pr``.
        var wf: Int?
        /// Official wage paid to workers.
        var wn: Int64

        /// Clerk raise probability, set if the factory couldn’t hire any clerks.
        var cf: Int?
        /// Official wage paid to clerks.
        var cn: Int64

        /// Input efficiency.
        var ei: Double
        /// Output efficiency.
        var eo: Double

        var fl: Double
        var fe: Double
        var fx: Double

        /// Share price.
        var px: Double
        /// A number between -1 and 1.
        var profitability: Double
    }
}
extension Factory.Dimensions {
    init() {
        self.init(
            vl: 0,
            ve: 0,
            vx: 0,
            wf: nil,
            wn: 1,
            cf: nil,
            cn: 1,
            ei: 1,
            eo: 1,
            fl: 0,
            fe: 0,
            fx: 0,
            px: 1,
            profitability: 1
        )
    }
}
extension Factory.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case vl = "vl"
        case ve = "ve"
        case vx = "vx"
        case wf = "wf"
        case wn = "wn"
        case cf = "cf"
        case cn = "cn"
        case ei = "ei"
        case eo = "eo"
        case fl = "fl"
        case fe = "fe"
        case fx = "fx"
        case px = "px"
        case profitability = "pa"
    }
}
extension Factory.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.vl] = self.vl
        js[.ve] = self.ve
        js[.vx] = self.vx
        js[.wf] = self.wf
        js[.wn] = self.wn
        js[.cf] = self.cf
        js[.cn] = self.cn
        js[.ei] = self.ei
        js[.eo] = self.eo
        js[.fl] = self.fl
        js[.fe] = self.fe
        js[.fx] = self.fx
        js[.px] = self.px
        js[.profitability] = self.profitability
    }
}
extension Factory.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            vl: try js[.vl]?.decode() ?? 0,
            ve: try js[.ve]?.decode() ?? 0,
            vx: try js[.vx]?.decode() ?? 0,
            wf: try js[.wf]?.decode(),
            wn: try js[.wn]?.decode() ?? 1,
            cf: try js[.cf]?.decode(),
            cn: try js[.cn]?.decode() ?? 1,
            ei: try js[.ei]?.decode() ?? 1,
            eo: try js[.eo]?.decode() ?? 1,
            fl: try js[.fl]?.decode() ?? 0,
            fe: try js[.fe]?.decode() ?? 0,
            fx: try js[.fx]?.decode() ?? 0,
            px: try js[.px]?.decode() ?? 0,
            profitability: try js[.profitability]?.decode() ?? 1,
        )
    }
}

#if TESTABLE
extension Factory.Dimensions: Equatable, Hashable {}
#endif
