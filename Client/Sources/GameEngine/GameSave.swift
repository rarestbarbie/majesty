import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

public struct GameSave {
    var symbols: GameRules.Symbols

    let date: GameDate
    let player: CountryID

    let cultures: [Culture]
    var countries: [Country]
    let factories: [Factory]
    var pops: [Pop]

    let markets: OrderedDictionary<Market.AssetPair, Market>
}
extension GameSave {
    public enum ObjectKey: JSString, Sendable {
        case symbols

        case date
        case player

        // case terrain
        // case planets
        case cultures
        case countries
        case factories
        case pops

        case markets
    }
}
extension GameSave: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.symbols] = self.symbols
        js[.date] = self.date
        js[.player] = self.player

        js[.cultures] = self.cultures
        js[.countries] = self.countries
        js[.factories] = self.factories
        js[.pops] = self.pops

        js[.markets] = self.markets
    }
}
extension GameSave: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            symbols: try js[.symbols].decode(),
            date: try js[.date].decode(),
            player: try js[.player].decode(),
            cultures: try js[.cultures].decode(),
            countries: try js[.countries].decode(),
            factories: try js[.factories].decode(),
            pops: try js[.pops].decode(),
            markets: try js[.markets].decode(),
        )
    }
}
