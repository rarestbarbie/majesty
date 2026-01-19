import GameClock
import JavaScriptInterop

extension GameSpeed {
    @frozen public enum ObjectKey: JSString, Sendable {
        case paused
        case ticks
    }
}
extension GameSpeed: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.paused] = self.paused
        js[.ticks] = self.ticks
    }
}
extension GameSpeed: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(paused: try js[.paused].decode(), ticks: try js[.ticks].decode())
    }
}
