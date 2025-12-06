import JavaScriptInterop
import JavaScriptKit
import GameIDs
import GameRules

@frozen public struct PopSeed: Identifiable {
    public var id: PopID?
    public let type: PopOccupation
    public let race: Symbol
    public let size: Int64
}
extension PopSeed {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case type
        case race
        case size
    }
}
extension PopSeed: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.id = try js[.id]?.decode()
        self.type = try js[.type].decode()
        self.race = try js[.race].decode()
        self.size = try js[.size].decode()
    }
}
