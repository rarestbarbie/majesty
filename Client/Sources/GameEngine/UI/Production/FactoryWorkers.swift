import JavaScriptKit
import JavaScriptInterop

struct FactoryWorkers {
    let aggregate: Workforce
}
extension FactoryWorkers: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count
        case limit
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.aggregate.count
        js[.limit] = self.aggregate.limit
    }
}
