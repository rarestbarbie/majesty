import GameEconomy
import JavaScriptKit
import JavaScriptInterop

enum MarketFilterLabel: Equatable {
    case currency(CurrencyLabel)
    case resource(ResourceLabel)
}
extension MarketFilterLabel: Identifiable {
    var id: Market.Asset {
        switch self {
        case .currency(let label): .fiat(label.id)
        case .resource(let label): .good(label.id)
        }
    }
}
extension MarketFilterLabel {
    var name: String {
        switch self {
        case .currency(let label): label.name
        case .resource(let label): label.name
        }
    }
}
extension MarketFilterLabel: Comparable {
    static func < (a: Self, b: Self) -> Bool { (a.name, a.id) < (b.name, b.id) }
}
extension MarketFilterLabel: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case icon
        case name
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        switch self {
        case .currency(let self):
            js[.icon] = ""
            js[.name] = self.name

        case .resource(let self):
            js[.icon] = self.icon
            js[.name] = self.name
        }
    }
}
