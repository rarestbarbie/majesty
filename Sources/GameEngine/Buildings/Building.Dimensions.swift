import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension Building {
    struct Dimensions: BackgroundableMetrics, LegalEntityMetrics {
        var active: Int64
        var vacant: Int64
        var vl: Int64
        var ve: Int64
        var vx: Int64

        var fl: Double
        var fe: Double
        var fx: Double

        var ei: Double
        /// Share price.
        var px: Double
        /// A number between -1 and 1.
        var profitability: Double
    }
}
extension Building.Dimensions {
    init() {
        self.init(
            active: 0,
            vacant: 0,
            vl: 0,
            ve: 0,
            vx: 0,
            fl: 0,
            fe: 0,
            fx: 0,
            ei: 1,
            px: 1,
            profitability: 0
        )
    }
}
extension Building.Dimensions {
    enum ObjectKey: JSString, Sendable {
        case active = "a"
        case vacant = "v"
        case vl
        case ve
        case vx
        case fl
        case fe
        case fx
        case ei
        case px
        case profitability = "pa"
    }
}
extension Building.Dimensions: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.active] = self.active
        js[.vacant] = self.vacant == 0 ? nil : self.vacant
        js[.vl] = self.vl
        js[.ve] = self.ve
        js[.vx] = self.vx
        js[.fl] = self.fl
        js[.fe] = self.fe
        js[.fx] = self.fx
        js[.ei] = self.ei
        js[.px] = self.px
        js[.profitability] = self.profitability
    }
}
extension Building.Dimensions: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            active: try js[.active]?.decode() ?? 0,
            vacant: try js[.vacant]?.decode() ?? 0,
            vl: try js[.vl]?.decode() ?? 0,
            ve: try js[.ve]?.decode() ?? 0,
            vx: try js[.vx]?.decode() ?? 0,
            fl: try js[.fl]?.decode() ?? 0,
            fe: try js[.fe]?.decode() ?? 0,
            fx: try js[.fx]?.decode() ?? 0,
            ei: try js[.ei]?.decode() ?? 1,
            px: try js[.px]?.decode() ?? 1,
            profitability: try js[.profitability]?.decode() ?? 0
        )
    }
}
