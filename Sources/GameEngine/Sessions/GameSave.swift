import GameEconomy
import GameIDs
import GameRules
import JavaScriptKit
import JavaScriptInterop
import Random
import OrderedCollections

public struct GameSave: Sendable {
    var symbols: GameSaveSymbols
    let random: PseudoRandom
    let player: CountryID
    let cultures: [Culture]

    let accounts: OrderedDictionary<LEI, Bank.Account>.Items
    let localMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
    let worldMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>
    let date: GameDate

    let currencies: [Currency]
    let countries: [Country]

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
        case cultures

        case accounts
        case markets_local
        case markets_world
        case date

        // case terrain
        // case planets
        case currencies
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
        js[.cultures] = self.cultures
        js[.accounts] = self.accounts
        js[.markets_local] = self.localMarkets
        js[.markets_world] = self.worldMarkets
        js[.date] = self.date

        js[.currencies] = self.currencies
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
            cultures: try js[.cultures].decode(),
            accounts: try js[.accounts]?.decode() ?? .init(dictionary: [:]),
            localMarkets: try js[.markets_local]?.decode() ?? [:],
            worldMarkets: try js[.markets_world]?.decode() ?? [:],
            date: try js[.date].decode(),
            currencies: try js[.currencies].decode(),
            countries: try js[.countries].decode(),
            buildings: try js[.buildings].decode(),
            factories: try js[.factories].decode(),
            mines: try js[.mines]?.decode() ?? [],
            pops: try js[.pops].decode(),
        )
    }
}
