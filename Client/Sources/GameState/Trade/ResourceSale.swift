import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct ResourceSale {
    let label: ResourceLabel
    let quantity: Int64
    let leftover: Int64
    let proceeds: Int64
}
extension ResourceSale: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case icon
        case quantity
        case leftover
        case proceeds
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.label.id
        js[.name] = self.label.name
        js[.icon] = self.label.icon
        js[.quantity] = self.quantity
        js[.leftover] = self.leftover
        js[.proceeds] = self.proceeds
    }
}
