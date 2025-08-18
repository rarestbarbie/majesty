import GameState
import JavaScriptInterop
import JavaScriptKit

struct GameDateComponents {
    let y: Int32
    let m: Int32
    let d: Int32
}
extension GameDateComponents {
    init(_ date: GameDate) {
        let (y, m, d): (Int32, Int32, Int32) = date.gregorian
        self.init(y: y, m: m, d: d)
    }
}
extension GameDateComponents {
    enum ObjectKey: JSString, Sendable {
        case y
        case m
        case d
    }
}
extension GameDateComponents: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.y] = y
        js[.m] = m
        js[.d] = d
    }
}
