import GameIDs
import JavaScriptInterop

@frozen public struct PopSeedGroup {
    public let tile: Address
    public let pops: [PopSeed]
}
extension PopSeedGroup {
    @frozen public enum ObjectKey: JSString, Sendable {
        case tile = "tile"
        case pops = "pops"
    }
}
extension PopSeedGroup: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.tile = try js[.tile].decode()
        self.pops = try js[.pops].decode()
    }
}
