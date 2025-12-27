import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameStarts
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

// should live in GameStarts, but needs ``Culture``
public struct GameStart: Sendable {
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

    let prices: SymbolTable<Exact>

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

    func unpack(rules: inout GameMetadata) throws -> GameSave {
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

        rules.pops.register(cultures: cultures)

        var random: PseudoRandom = self.random

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

        // some pops are not sapient enough to be transgender
        func pNonsapient(gender: Gender) -> Int64 {
            switch gender {
            case .FT: return 0
            case .FTS: return 0
            case .FC: return 4_000
            case .FCS: return 46_000
            case .XTL: return 0
            case .XT: return 0
            case .XTG: return 0
            case .XCL: return 0_550
            case .XC: return 0_550
            case .XCG: return 0_550
            case .MT: return 0
            case .MTS: return 0
            case .MC: return 2_000
            case .MCS: return 48_000
            }
        }
        func p(gender: Gender) -> Int64 {
            switch gender {
            case .FT: return 0_150
            case .FTS: return 0_150
            case .FC: return 4_000
            case .FCS: return 45_000
            case .XTL: return 0_400
            case .XT: return 0_400
            case .XTG: return 0_200
            case .XCL: return 0_006
            case .XC: return 0_006
            case .XCG: return 0_006
            case .MT: return 0_200
            case .MTS: return 0_200
            case .MC: return 2_000
            case .MCS: return 48_000
            }
        }
        for group: PopSeedGroup in self.pops {
            for seed: PopSeed in group.pops {
                let genders: [Gender] = Gender.allCases.shuffled(using: &random.generator)
                guard
                let sizes: [Int64] = genders.distribute(
                    seed.size,
                    share: seed.type.stratum <= .Ward
                        ? pNonsapient(gender:)
                        : p(gender:)
                ) else {
                    continue
                }
                for (gender, size): (Gender, Int64) in zip(genders, sizes) {
                    let section: Pop.Section = .init(
                        type: .init(
                            occupation: seed.type,
                            gender: gender,
                            race: try symbols.cultures[seed.race]
                        ),
                        tile: group.tile
                    )
                    var pop: Pop = .init(id: seed.id ?? pop.increment(), section: section)

                    pop.y.active = size
                    pop.z.active = size
                    pops.append(pop)
                }
            }
        }

        var accounts: OrderedDictionary<LEI, Bank.Account> = [:]
        // this is very slow, but we only do it once when initializing a new game
        for seed: PopWealth in self.popWealth {
            for pop: Pop in pops {
                if  let race: Symbol = seed.race, try symbols.cultures[race] != pop.race {
                    continue
                }
                if  pop.occupation != seed.type {
                    continue
                }

                accounts[.pop(pop.id), default: .zero].s += seed.cash * pop.z.total
            }
        }

        var tradeable: WorldMarkets = .init(settings: rules.settings.exchange)
        var segmented: LocalMarkets = .init()
        /// ordering is important for determinism
        let prices: [(Resource, Exact)] = try self.prices.quantities(
            keys: symbols.static.resources
        )

        for (resource, exact): (Resource, Exact) in prices {
            let (n, d): (Int64, denominator: Int64?) = exact.value.fraction
            let resource: ResourceMetadata = rules.resources[resource]
            if  resource.local {
                for country: Country in countries {
                    let fraction: Fraction = (n * country.minwage) %/ (d ?? 1)
                    if  fraction < 1 {
                        // we probably do not want local prices to start below 1 currency unit
                        continue
                    }

                    let price: LocalPrice = .init(fraction)
                    for tile: Address in country.tilesControlled {
                        {
                            $0.today.bid = price
                            $0.today.ask = price
                            $0.yesterday = $0.today
                            // important! we need to pretend there was some activity yesterday
                            // or the price will reset instantly on the first game day
                            $0.yesterday.supply = 1
                            $0.yesterday.demand = 1
                            // this is okay because we don’t have any invariants on the previous
                            // day’s trading volume
                        } (&segmented[resource.id / tile])
                    }
                }
            } else {
                let l: Double = rules.settings.exchange.capital.liquidity
                let n: Double = Double.init(n)
                let d: Double = Double.init(d ?? 1)
                for currency: Currency in self.currencies {
                    // we want to satisfy:
                    //
                    // 1.   q / b = n / d
                    // 2.   sqrt(q * b) = l
                    //
                    // which gives us:
                    //      q = l² / b
                    //      b = l² / q
                    //
                    //      q² / l² = n / d
                    //      q² = n / d * l²
                    //      q = l * sqrt(n / d)
                    //
                    //      b = l² / (sqrt(n / d) * l)
                    //      b = l / sqrt(n / d)
                    //      b = l * sqrt(d / n)
                    {
                        let q: Double = l * Double.sqrt(n / d)
                        let b: Double = l * Double.sqrt(d / n)
                        $0.assets.quote = max(2, Int64.init(q.rounded()))
                        $0.assets.base = max(2, Int64.init(b.rounded()))

                    } (&tradeable[resource.id / currency.id])
                }
            }
        }

        return .init(
            symbols: symbols.static,
            random: random,
            player: self.player,
            cultures: cultures,
            accounts: accounts.items,
            segmentedMarkets: segmented.markets,
            tradeableMarkets: tradeable.markets,
            date: self.date,
            currencies: self.currencies,
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

        case prices

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
            prices: try js[.prices].decode(),
            symbols: try js[.symbols].decode()
        )
    }
}
