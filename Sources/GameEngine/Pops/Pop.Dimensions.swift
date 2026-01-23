import JavaScriptInterop

extension Pop {
    struct Dimensions: LegalEntityMetrics {
        var active: Int64
        var vacant: Int64
        var mil: Double
        var con: Double
        var fl: Double
        var fe: Double
        var fx: Double
        var vl: Int64
        var ve: Int64
        var vx: Int64
        var vout: Int64
        var px: Double
        /// A number between -1 and 1.
        var profitability: Double
    }
}
extension Pop.Dimensions: BackgroundableMetrics {
    static var mothballing: Double { -0.1 }
    static var restoration: Double { 0.04 }
    // slave culling is determined by technology, so setting attrition to 200% scales the
    // input parameter to the range [0, 1], since we are multiplying it by the actual rate later
    static var attrition: Double { 2 }
    static var vertex: Double { 0.5 }
}
extension Pop.Dimensions {
    init() {
        self.init(
            active: 0,
            vacant: 0,
            mil: 0,
            con: 0,
            fl: 0,
            fe: 0,
            fx: 0,
            vl: 0,
            ve: 0,
            vx: 0,
            vout: 0,
            px: 1,
            profitability: 0
        )
    }
}
extension Pop.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case active = "a"
        case vacant = "v"
        case mil = "mil"
        case con = "con"
        case fl = "fl"
        case fe = "fe"
        case fx = "fx"
        case vl = "vl"
        case ve = "ve"
        case vx = "vx"
        case vout = "vout"
        case px = "px"
        case profitability = "pa"
    }
}
extension Pop.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.active] = self.active
        js[.vacant] = self.vacant == 0 ? nil : self.vacant
        js[.mil] = self.mil
        js[.con] = self.con
        js[.fl] = self.fl
        js[.fe] = self.fe
        js[.fx] = self.fx
        js[.vl] = self.vl
        js[.ve] = self.ve
        js[.vx] = self.vx
        js[.vout] = self.vout == 0 ? nil : self.vout
        js[.px] = self.px
        js[.profitability] = self.profitability
    }
}
extension Pop.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            active: try js[.active]?.decode() ?? 0,
            vacant: try js[.vacant]?.decode() ?? 0,
            mil: try js[.mil]?.decode() ?? 0,
            con: try js[.con]?.decode() ?? 0,
            fl: try js[.fl]?.decode() ?? 0,
            fe: try js[.fe]?.decode() ?? 0,
            fx: try js[.fx]?.decode() ?? 0,
            vl: try js[.vl]?.decode() ?? 0,
            ve: try js[.ve]?.decode() ?? 0,
            vx: try js[.vx]?.decode() ?? 0,
            vout: try js[.vout]?.decode() ?? 0,
            px: try js[.px]?.decode() ?? 1,
            profitability: try js[.profitability]?.decode() ?? 0,
        )
    }
}

#if TESTABLE
extension Pop.Dimensions: Equatable {}
#endif
