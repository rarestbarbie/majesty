import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension Building {
    struct Dimensions: LegalEntityMetrics {
        var vl: Int64
        var ve: Int64
        var vx: Int64

        var fl: Double
        var fe: Double
        var fx: Double

        /// Share price.
        var px: Double
        /// A number between -1 and 1.
        var profitability: Double
    }
}
extension Building.Dimensions {
    init() {
        self.init(
            vl: 0,
            ve: 0,
            vx: 0,
            fl: 0,
            fe: 0,
            fx: 0,
            px: 1,
            profitability: 1
        )
    }
}