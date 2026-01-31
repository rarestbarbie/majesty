import JavaScriptInterop
import GameUI

extension Pop {
    struct Dimensions {
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
        /// For an enslaved pop, this is the price per share; for a free pop, this is the
        /// mark-to-market value of her investment portfolio.
        var priceOrEquity: Double
        /// A number between -1 and 1.
        var profitability: Double
    }
}
extension Pop.Dimensions: MeanAggregatable {
    /// These are the only fields that make sense to average, the rest are already averages
    var weighted: (
        portfolioValue: Double,
        vl: Int64,
        ve: Int64,
        vx: Int64,
        vout: Int64
    ) {
        (
            portfolioValue: self.portfolioValue,
            vl: self.vl,
            ve: self.ve,
            vx: self.vx,
            vout: self.vout
        )
    }
    var weight: Double {
        // this only makes sense for free pops, who are never backgrounded
        Double.init(self.active)
    }
}
extension Pop.Dimensions {
    /// Only valid for free pops
    var portfolioValue: Double { self.priceOrEquity }
}
extension Pop.Dimensions: LegalEntityMetrics {
    /// Only valid for enslaved pops
    var px: Double { self.priceOrEquity }
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
            priceOrEquity: 0,
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
        case priceOrEquity = "xx"
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
        js[.priceOrEquity] = self.priceOrEquity
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
            priceOrEquity: try js[.priceOrEquity]?.decode() ?? 1,
            profitability: try js[.profitability]?.decode() ?? 0,
        )
    }
}

#if TESTABLE
extension Pop.Dimensions: Equatable {}
#endif
