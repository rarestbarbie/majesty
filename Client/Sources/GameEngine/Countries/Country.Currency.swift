import GameIDs
import JavaScriptInterop
import JavaScriptKit

extension Country {
    struct Currency: Identifiable {
        let id: Fiat
        let name: String
        let long: String
    }
}
extension Country.Currency {
    var label: CurrencyLabel {
        .init(id: self.id, name: self.name)
    }
}
extension Country.Currency {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case long
    }
}
extension Country.Currency: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.long] = self.long
    }
}
extension Country.Currency: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name].decode(),
            long: try js[.long].decode()
        )
    }
}
