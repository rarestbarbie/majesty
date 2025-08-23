import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct ResourceNeed {
    let label: ResourceLabel
    let tier: ResourceNeedTier

    let acquired: Int64
    let capacity: Int64
    let demanded: Int64
    let consumed: Int64
    let purchased: Int64
}
extension ResourceNeed {
    init(label: ResourceLabel, input: ResourceInput, tier: ResourceNeedTier) {
        self.init(
            label: label,
            tier: tier,
            acquired: input.acquired,
            capacity: input.capacity,
            demanded: input.demanded,
            consumed: input.consumed,
            purchased: input.purchased,
        )
    }
}
extension ResourceNeed: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case icon
        case tier
        case acquired
        case capacity
        case demanded
        case consumed
        case purchased
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.label.id
        js[.name] = self.label.name
        js[.icon] = self.label.icon
        js[.tier] = self.tier
        js[.acquired] = self.acquired
        js[.capacity] = self.capacity
        js[.demanded] = self.demanded
        js[.consumed] = self.consumed
        js[.purchased] = self.purchased
    }
}
