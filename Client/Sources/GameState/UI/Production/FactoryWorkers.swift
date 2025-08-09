import GameRules
import JavaScriptKit
import JavaScriptInterop

struct FactoryWorkers {
    let type: PopType
    let aggregate: FactoryContext.Workforce
}
extension FactoryWorkers: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case limit
        case union
        case striking
        case nonunion
        case hire
        case fire
        case quit
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = self.type.plural
        js[.limit] = self.aggregate.limit
        js[.union] = self.aggregate.u.count
        js[.striking] = self.aggregate.s.count
        js[.nonunion] = self.aggregate.n.count
        js[.hire] = self.aggregate.hire
        js[.fire] = self.aggregate.fire
        js[.quit] = self.aggregate.quit
    }
}
