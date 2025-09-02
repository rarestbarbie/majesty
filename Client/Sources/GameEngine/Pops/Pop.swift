import Assert
import GameConditions
import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import Random
import OrderedCollections

struct Pop: CashAccountHolder, IdentityReplaceable {
    var id: PopID
    let home: Address
    let type: PopType
    let nat: String

    var cash: CashAccount

    /// Life Needs
    var nl: ResourceInputs
    /// Everyday Needs
    var ne: ResourceInputs
    /// Luxury Needs
    var nx: ResourceInputs

    var out: ResourceOutputs

    var yesterday: Dimensions
    var today: Dimensions

    var stocks: OrderedDictionary<FactoryID, Property<Factory>>
    var slaves: OrderedDictionary<PopID, Property<Pop>>
    var jobs: OrderedDictionary<FactoryID, FactoryJob>
}
extension Pop: Sectionable {
    init(id: PopID, section: Section) {
        self.init(
            id: id,
            home: section.home,
            type: section.type,
            nat: section.culture,
            cash: .init(),
            nl: .init(),
            ne: .init(),
            nx: .init(),
            out: .init(),
            yesterday: .init(),
            today: .init(),
            stocks: [:],
            slaves: [:],
            jobs: [:]
        )
    }

    var section: Section {
        .init(culture: self.nat, type: self.type, home: self.home)
    }
}
extension Pop: Turnable {
    mutating func turn() {
        var remove: [Int] = []
        for i: Int in self.jobs.values.indices {
            {
                $0.turn()
                if $0.count <= 0 {
                    remove.append(i)
                }
            } (&self.jobs.values[i])
        }
        for i: Int in remove.reversed() {
            self.jobs.remove(at: i)
        }

        self.cash.settle()
    }
}
extension Pop {
    mutating func egress(
        evaluator: ConditionEvaluator,
        direction: (PopStratum, PopStratum) -> Bool,
        on map: inout GameMap
    ) {
        let rate: Double = evaluator.output
        if  rate <= 0 {
            return
        }

        let count: Int64 = Binomial[self.today.size, rate].sample(
            using: &map.random.generator
        )
        var targets: [(id: PopType, weight: Int64)] = PopType.allCases.filter {
            direction(self.type.stratum, $0.stratum) && $0.stratum != .Ward
        }.map {
            (id: $0, weight: 1)
        }

        targets.shuffle(using: &map.random.generator)

        guard
        let breakdown: [Int64] = targets.distribute(count, share: \.weight) else {
            return
        }

        for ((target, _), count): ((id: PopType, Int64), Int64) in zip(targets, breakdown)
            where count > 0 {

            if self.type == target {
                // No need to convert to the same type
                continue
            }

            let section: Section = .init(
                culture: self.nat,
                type: target,
                home: self.home
            )

            map.conversions.append((count: count, to: section))
            self.today.size -= count
        }

        #assert(
            self.today.size >= 0,
            "Pop (id = \(self.id)) has negative size (\(self.today.size))!"
        )
    }
}
extension Pop {
    /// It is better to compute this dynamically, as the pop count itself can change, and that
    /// might invalidate cached values for unemployment!
    var unemployed: Int64 {
        self.jobs.values.reduce(self.today.size) { $0 - $1.count }
    }

    var decadence: Double {
        0.1 * self.yesterday.con
    }

    var needsPerCapita: (l: Double, e: Double, x: Double) {
        let decadence: Double = self.decadence
        return (
            l: 1 + decadence,
            e: 1 + decadence * 2,
            x: 1 + decadence * 3
        )
    }
}
extension Pop {
    enum ObjectKey: JSString, Sendable {
        case id
        case home = "on"
        case type
        case nat
        case cash
        case nl
        case ne
        case nx
        case out

        case yesterday_size = "y_size"
        case yesterday_mil = "y_mil"
        case yesterday_con = "y_con"
        case yesterday_fl = "y_fl"
        case yesterday_fe = "y_fe"
        case yesterday_fx = "y_fx"

        case today_size = "t_size"
        case today_mil = "t_mil"
        case today_con = "t_con"
        case today_fl = "t_fl"
        case today_fe = "t_fe"
        case today_fx = "t_fx"

        case stocks
        case slaves
        case jobs
    }
}
extension Pop: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.home] = self.home
        js[.type] = self.type
        js[.nat] = self.nat
        js[.cash] = self.cash
        js[.nl] = self.nl
        js[.ne] = self.ne
        js[.nx] = self.nx
        js[.out] = self.out

        js[.yesterday_size] = self.yesterday.size
        js[.yesterday_mil] = self.yesterday.mil
        js[.yesterday_con] = self.yesterday.con
        js[.yesterday_fl] = self.yesterday.fl
        js[.yesterday_fe] = self.yesterday.fe
        js[.yesterday_fx] = self.yesterday.fx

        js[.today_size] = self.today.size
        js[.today_mil] = self.today.mil
        js[.today_con] = self.today.con
        js[.today_fl] = self.today.fl
        js[.today_fe] = self.today.fe
        js[.today_fx] = self.today.fx

        js[.stocks] = self.stocks.isEmpty ? nil : self.stocks
        js[.slaves] = self.slaves.isEmpty ? nil : self.slaves
        js[.jobs] = self.jobs.isEmpty ? nil : self.jobs
    }
}
extension Pop: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = .init(
            size: try js[.today_size].decode(),
            mil: try js[.today_mil]?.decode() ?? 0,
            con: try js[.today_con]?.decode() ?? 0,
            fl: try js[.today_fl]?.decode() ?? 0,
            fe: try js[.today_fe]?.decode() ?? 0,
            fx: try js[.today_fx]?.decode() ?? 0,
        )
        self.init(
            id: try js[.id]?.decode() ?? 0,
            home: try js[.home].decode(),
            type: try js[.type].decode(),
            nat: try js[.nat].decode(),
            cash: try js[.cash]?.decode() ?? .init(),
            nl: try js[.nl]?.decode() ?? .init(),
            ne: try js[.ne]?.decode() ?? .init(),
            nx: try js[.nx]?.decode() ?? .init(),
            out: try js[.out]?.decode() ?? .init(),
            yesterday: .init(
                size: try js[.yesterday_size]?.decode() ?? today.size,
                mil: try js[.yesterday_mil]?.decode() ?? today.mil,
                con: try js[.yesterday_con]?.decode() ?? today.con,
                fl: try js[.yesterday_fl]?.decode() ?? today.fl,
                fe: try js[.yesterday_fe]?.decode() ?? today.fe,
                fx: try js[.yesterday_fx]?.decode() ?? today.fx,
            ),
            today: today,
            stocks: try js[.stocks]?.decode() ?? [:],
            slaves: try js[.slaves]?.decode() ?? [:],
            jobs: try js[.jobs]?.decode() ?? [:],
        )
    }
}

#if TESTABLE
extension Pop: Equatable, Hashable {}
#endif
