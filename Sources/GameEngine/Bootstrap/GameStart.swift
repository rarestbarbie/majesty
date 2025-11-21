import GameEconomy
import GameIDs
import GameRules
import GameStarts
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

extension GameStart {
    struct Symbols {
        let `static`: GameSaveSymbols
        // TODO: cultures go here
    }
}

// should live in GameStarts, but needs ``Culture``
public struct GameStart {
    let date: GameDate
    let player: CountryID
    let random: PseudoRandom

    // TODO
    let cultures: [Culture]

    let countries: [CountrySeed]
    let factories: [FactorySeedGroup]
    let popWealth: [PopWealth]
    let pops: [PopSeedGroup]

    var symbols: GameSaveSymbols
}
extension GameStart {
    private static func highest<Seed, ID>(
        in seeds: some Sequence<Seed>
    ) -> ID where Seed: Identifiable, Seed.ID == ID?, ID: GameID {
        var highest: ID = 0
        for seed: Seed in seeds {
            if  let id: ID = seed.id,
                    id > highest {
                highest = id
            }
        }
        return highest
    }

    func unpack() throws -> GameSave {
        let symbols: GameStart.Symbols = .init(static: self.symbols)

        var countries: [Country] = []
        var country: CountryID = Self.highest(in: self.countries)
        for seed: CountrySeed in self.countries {
            let country: Country = .init(
                id: seed.id ?? country.increment(),
                name: seed.name,
                culturePreferred: seed.culturePreferred.name,
                culturesAccepted: seed.culturesAccepted.map(\.name),
                researched: try seed.researched.map { try symbols.static.technologies[$0] },
                currency: seed.currency,
                minwage: seed.minwage,
                tilesControlled: seed.tiles,
            )
            countries.append(country)
        }

        var factories: [Factory] = []
        var factory: FactoryID = 0
        for group: FactorySeedGroup in self.factories {
            for seed: Symbol in group.factories {
                let section: Factory.Section = .init(
                    type: try symbols.static.factories[seed],
                    tile: group.tile
                )
                var factory: Factory = .init(id: factory.increment(), section: section)

                factory.size = .init(level: 0, growthProgress: Factory.Size.growthRequired - 1)
                factories.append(factory)
            }
        }

        var pops: [Pop] = []
        var pop: PopID = Self.highest(in: self.pops.lazy.map(\.pops).joined())
        for group: PopSeedGroup in self.pops {
            for seed: PopSeed in group.pops {
                let section: Pop.Section = .init(
                    culture: seed.race.name,
                    type: seed.type,
                    tile: group.tile
                )
                var pop: Pop = .init(id: seed.id ?? pop.increment(), section: section)

                pop.y.size = seed.size
                pop.z.size = seed.size
                pops.append(pop)
            }
        }

        var accounts: OrderedDictionary<LEI, Bank.Account> = [:]
        // this is very slow, but we only do it once when initializing a new game
        for seed: PopWealth in self.popWealth {
            for pop: Pop in pops {
                if  let nat: String = seed.nat, pop.nat != nat {
                    continue
                }
                if  pop.type != seed.type {
                    continue
                }

                accounts[.pop(pop.id), default: .zero].s += seed.cash * pop.z.size
            }
        }

        return .init(
            symbols: symbols.static,
            random: self.random,
            player: self.player,
            accounts: accounts.items,
            tradeableMarkets: [:],
            inelasticMarkets: [:],
            date: self.date,
            cultures: self.cultures,
            countries: countries,
            factories: factories,
            mines: [],
            pops: pops,
        )
    }
}
extension GameStart {
    public enum ObjectKey: JSString, Sendable {
        case date
        case random
        case player

        case cultures
        case countries
        case factories
        case pop_wealth
        case pops

        case symbols
    }
}
extension GameStart: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            date: try js[.date].decode(),
            player: try js[.player].decode(),
            random: try js[.random]?.decode() ?? .init(seed: 12345),
            cultures: try js[.cultures].decode(),
            countries: try js[.countries].decode(),
            factories: try js[.factories].decode(),
            popWealth: try js[.pop_wealth].decode(),
            pops: try js[.pops].decode(),
            symbols: try js[.symbols].decode()
        )
    }
}
