import GameEconomy
import GameState

extension Pop {
    struct Conversion {
        let from: PopID
        let size: Int64
        let of: Int64
        let to: Section
    }
}
extension Pop.Conversion {
    var inherits: Fraction {
        // it should be impossible to have `of == 0`
        self.size %/ self.of
    }
}
