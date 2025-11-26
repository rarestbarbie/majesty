import GameEconomy
import GameIDs
import GameRules
import JavaScriptKit
import JavaScriptInterop
import Random
import OrderedCollections

public struct GameSave {
    var symbols: GameSaveSymbols
    let random: PseudoRandom
    let player: CountryID

    let accounts: OrderedDictionary<LEI, Bank.Account>.Items
    let segmentedMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
    let tradeableMarkets: OrderedDictionary<BlocMarket.ID, BlocMarket>
    let date: GameDate

    let cultures: [Culture]
    var countries: [Country]

    let buildings: [Building]
    let factories: [Factory]
    let mines: [Mine]
    var pops: [Pop]
}
extension GameSave {
    public enum ObjectKey: JSString, Sendable {
        case symbols
        case random
        case player

        case accounts
        case markets_segmented
        case markets_tradeable
        case date

        // case terrain
        // case planets
        case cultures
        case countries
        case buildings
        case factories
        case mines
        case pops

        case seed_factories
        case seed_pops
    }
}
extension GameSave: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.symbols] = self.symbols
        js[.random] = self.random
        js[.player] = self.player
        js[.accounts] = self.accounts
        js[.markets_segmented] = self.segmentedMarkets
        js[.markets_tradeable] = self.tradeableMarkets
        js[.date] = self.date

        js[.cultures] = self.cultures
        js[.countries] = self.countries
        js[.buildings] = self.buildings
        js[.factories] = self.factories
        js[.mines] = self.mines
        js[.pops] = self.pops
    }
}
extension GameSave: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            symbols: try js[.symbols].decode(),
            random: try js[.random].decode(),
            player: try js[.player].decode(),
            accounts: try js[.accounts]?.decode() ?? .init(dictionary: [:]),
            segmentedMarkets: try js[.markets_segmented]?.decode() ?? [:],
            tradeableMarkets: try js[.markets_tradeable]?.decode() ?? [:],
            date: try js[.date].decode(),
            cultures: try js[.cultures].decode(),
            countries: try js[.countries].decode(),
            buildings: try js[.buildings].decode(),
            factories: try js[.factories].decode(),
            mines: try js[.mines]?.decode() ?? [],
            pops: try js[.pops].decode(),
        )
    }
}
