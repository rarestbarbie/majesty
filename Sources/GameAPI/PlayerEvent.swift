import JavaScriptInterop

enum PlayerEvent {
    case faster
    case slower
    case pause
    case tick
}
extension PlayerEvent: JavaScriptDecodable {
    enum ObjectKey: JSString, Sendable {
        case id
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let id: PlayerEventID = try js[.id].decode()

        switch id {
        case .Faster:   self = .faster
        case .Slower:   self = .slower
        case .Pause:    self = .pause
        case .Tick:     self = .tick
        }
    }
}
