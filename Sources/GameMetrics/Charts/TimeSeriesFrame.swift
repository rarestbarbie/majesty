import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TimeSeriesFrame {
    @usableFromInline let id: GameDate
    @usableFromInline let value: Double

    @inlinable init(id: GameDate, value: Double) {
        self.id = id
        self.value = value
    }
}
extension TimeSeriesFrame: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case y
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.y] = self.value
    }
}
