import GameIDs
import JavaScriptInterop

extension Currency {
    var label: CurrencyLabel {
        .init(id: self.id, name: self.name)
    }
}
