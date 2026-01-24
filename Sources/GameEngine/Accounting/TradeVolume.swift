import D
import GameUI

struct TradeVolume {
    var unitsProduced: Int64
    var unitsConsumed: Int64
    var valueProduced: Int64
    var valueConsumed: Int64
}
extension TradeVolume {
    static var zero: Self {
        .init(unitsProduced: 0, unitsConsumed: 0, valueProduced: 0, valueConsumed: 0)
    }
}
extension TradeVolume {
    static func += (ul: inout TooltipInstructionEncoder, self: Self)  {
        let surplus: Int64 = self.unitsProduced - self.unitsConsumed
        ul[surplus < 0 ? "Deficit" : "Surplus", +] = +surplus[/3]
    }
}
