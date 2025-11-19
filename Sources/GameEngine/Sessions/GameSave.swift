import GameEconomy
import GameRules
import GameIDs
import JavaScriptKit
import JavaScriptInterop
import Random
import OrderedCollections

public struct GameSave {
    var symbols: GameSaveSymbols
    let random: PseudoRandom
    let player: CountryID

    let accounts: OrderedDictionary<LEI, Bank.Account>.Items
    let tradeableMarkets: OrderedDictionary<BlocMarket.ID, BlocMarket>
    let inelasticMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
    let date: GameDate

    let cultures: [Culture]
    var countries: [Country]

    let factories: [Factory]
    let mines: [Mine]
    var pops: [Pop]

    let _factories: [FactorySeed]
    let _pops: [PopSeed]
}
extension GameSave {
    public enum ObjectKey: JSString, Sendable {
        case symbols
        case random
        case player

        case accounts
        case markets_tradeable
        case markets_inelastic
        case date

        // case terrain
        // case planets
        case cultures
        case countries
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
        js[.markets_tradeable] = self.tradeableMarkets
        js[.markets_inelastic] = self.inelasticMarkets
        js[.date] = self.date

        js[.cultures] = self.cultures
        js[.countries] = self.countries
        js[.factories] = self.factories
        js[.mines] = self.mines
        js[.pops] = self.pops
    }
}
extension GameSave: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            symbols: try js[.symbols].decode(),
            random: try js[.random]?.decode() ?? .init(seed: 12345),
            player: try js[.player].decode(),
            accounts: try js[.accounts]?.decode() ?? .init(dictionary: [:]),
            tradeableMarkets: try js[.markets_tradeable]?.decode() ?? [:],
            inelasticMarkets: try js[.markets_inelastic]?.decode() ?? [:],
            date: try js[.date].decode(),
            cultures: try js[.cultures].decode(),
            countries: try js[.countries].decode(),
            factories: try js[.factories].decode(),
            mines: try js[.mines]?.decode() ?? [],
            pops: try js[.pops].decode(),
            _factories: try js[.seed_factories]?.decode() ?? [],
            _pops: try js[.seed_pops]?.decode() ?? []
        )
    }
}
