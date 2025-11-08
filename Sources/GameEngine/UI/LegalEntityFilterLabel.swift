import JavaScriptKit
import JavaScriptInterop

protocol LegalEntityFilterLabel: JavaScriptEncodable<LegalEntityFilterLabelObjectKey>, Identifiable, Equatable, Comparable where ID: ConvertibleToJSValue {
    var name: String { get }
}
extension LegalEntityFilterLabel {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
    }
}

enum LegalEntityFilterLabelObjectKey: JSString, Sendable {
    case id
    case name
}
