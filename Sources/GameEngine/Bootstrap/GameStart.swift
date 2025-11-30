import GameEconomy
import GameIDs
import GameRules
import GameStarts
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

// should live in GameStarts, but needs ``Culture``
public struct GameStart {
    let date: GameDate
    let player: CountryID
    let random: PseudoRandom

    // TODO
    let currencies: [Currency]
    let cultures: [CultureSeed]

    let countries: [CountrySeed]
    let buildings: [BuildingSeedGroup]
    let factories: [FactorySeedGroup]
    let popWealth: [PopWealth]
    let pops: [PopSeedGroup]

    var symbols: GameSaveSymbols
}
extension GameStart {
    static func highest<Seed, ID>(
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

    func unpack(rules: GameRules) throws -> GameSave {
        let symbols: GameStart.Symbols = .init(static: self.symbols, cultures: self.cultures)

        let starter: Set<Technology> = rules.technologies.values.reduce(into: []) {
            if  $1.starter {
                $0.insert($1.id)
            }
        }
        let cultures: [Culture] = try self.cultures.map {
            .init(
                id: try symbols.cultures[$0.name],
                name: $0.name.name,
                type: try symbols.static[biology: $0.type ?? "_Pet"],
                color: $0.color
            )
        }

        var countries: [Country] = []
        var country: CountryID = Self.highest(in: self.countries)
        for seed: CountrySeed in self.countries {
            let researched: Set<Technology> = try seed.researched.reduce(into: starter) {
                $0.insert(try symbols.static.technologies[$1])
            }
            let country: Country = .init(
                id: seed.id ?? country.increment(),
                name: seed.name,
                culturePreferred: try symbols.cultures[seed.culturePreferred],
                culturesAccepted: try seed.culturesAccepted.map { try symbols.cultures[$0] },
                researched: researched.sorted(),
                currency: seed.currency,
                suzerain: seed.suzerain,
                minwage: seed.minwage ?? 5,
                tilesControlled: seed.tiles,
            )
            countries.append(country)
        }

        var buildings: [Building] = []
        var building: BuildingID = 0
        for group: BuildingSeedGroup in self.buildings {
            for seed: Quantity<BuildingType> in try group.buildings.quantities(
                    keys: symbols.static.buildings
                ) {
                let section: Building.Section = .init(type: seed.unit, tile: group.tile)
                var building: Building = .init(id: building.increment(), section: section)

                building.z.active = seed.amount
                buildings.append(building)
            }
        }

        var factories: [Factory] = []
        var factory: FactoryID = 0
        for group: FactorySeedGroup in self.factories {
            for seed: Quantity<FactoryType> in try group.factories.quantities(
                    keys: symbols.static.factories
                ) {
                let section: Factory.Section = .init(
                    type: seed.unit,
                    tile: group.tile
                )
                var factory: Factory = .init(id: factory.increment(), section: section)

                factory.size = .init(level: seed.amount)
                factories.append(factory)
            }
        }

        var pops: [Pop] = []
        var pop: PopID = Self.highest(in: self.pops.lazy.map(\.pops).joined())
        for group: PopSeedGroup in self.pops {
            for seed: PopSeed in group.pops {
                let section: Pop.Section = .init(
                    race: try symbols.cultures[seed.race],
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
                if  let race: Symbol = seed.race, try symbols.cultures[race] != pop.race {
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
            segmentedMarkets: [:],
            tradeableMarkets: [:],
            date: self.date,
            currencies: self.currencies,
            cultures: cultures,
            countries: countries,
            buildings: buildings,
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
        case buildings
        case factories
        case pop_wealth
        case pops
        case currencies

        case symbols
    }
}
extension GameStart: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            date: try js[.date].decode(),
            player: try js[.player].decode(),
            random: try js[.random]?.decode() ?? .init(seed: 12345),
            currencies: try js[.currencies].decode(),
            cultures: try js[.cultures].decode(),
            countries: try js[.countries].decode(),
            buildings: try js[.buildings].decode(),
            factories: try js[.factories].decode(),
            popWealth: try js[.pop_wealth].decode(),
            pops: try js[.pops].decode(),
            symbols: try js[.symbols].decode()
        )
    }
}
