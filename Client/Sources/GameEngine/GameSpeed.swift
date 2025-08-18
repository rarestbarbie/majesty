import JavaScriptKit
import JavaScriptInterop

@frozen public struct GameSpeed {
    public var paused: Bool
    public var ticks: Int

    @inlinable public init(paused: Bool = true, ticks: Int = 3) {
        self.paused = paused
        self.ticks = ticks
    }
}
extension GameSpeed {
    var period: Int {
        switch self.ticks {
        case 1: return 1
        case 2: return 2
        case 3: return 4
        case 4: return 8
        case _: return 12
        }
    }
}
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
