import GameEngine
import JavaScriptKit
import JavaScriptInterop

struct PopJobDescription {
    // let id: GameID<Factory>
    let name: String
    let size: Int64
    let hire: Int64
    let fire: Int64
    let quit: Int64
}
extension PopJobDescription: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        // case id
        case name
        case size
        case hire
        case fire
        case quit
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        // js[.id] = self.id
        js[.name] = self.name
        js[.size] = self.size
        js[.hire] = self.hire
        js[.fire] = self.fire
        js[.quit] = self.quit
    }
}
