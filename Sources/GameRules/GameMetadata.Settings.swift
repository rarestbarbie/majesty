import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension GameMetadata {
    @frozen public struct Settings {
        public let worldMarkets: WorldMarkets.Settings
        public let localMarkets: LocalMarkets.Settings
    }
}
extension GameMetadata.Settings: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case world_markets
        case local_markets
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            worldMarkets: try js[.world_markets].decode(),
            localMarkets: try js[.local_markets].decode()
        )
    }
}
