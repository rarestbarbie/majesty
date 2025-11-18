import D
import GameEconomy
import GameUI

extension Reservoir {
    subscript(format: BigIntFormat) -> TooltipInstruction.Ticker {
        self.total[format] ^^ self.change
    }
}
