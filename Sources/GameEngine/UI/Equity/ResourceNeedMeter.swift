import JavaScriptInterop

struct ResourceNeedMeter {
    let id: ResourceTierIdentifier
    let label: String
    let value: Double
}
extension ResourceNeedMeter: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case label
        case value
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.label] = self.label
        js[.value] = self.value
    }
}
