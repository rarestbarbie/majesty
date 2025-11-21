import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension Currency {
    var label: CurrencyLabel {
        .init(id: self.id, name: self.name)
    }
}
