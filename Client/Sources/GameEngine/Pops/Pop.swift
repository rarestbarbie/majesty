import Assert
import GameConditions
import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import Random
import OrderedCollections

struct Pop: LegalEntityState, IdentityReplaceable {
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

    var equity: Equity<LEI>
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
            equity: [:],
            jobs: [:]
        )
    }

    var section: Section {
        .init(culture: self.nat, type: self.type, home: self.home)
    }
}
extension Pop {
    mutating func prune(in context: GameContext.PruningPass) {
        self.equity.prune(in: context)
        self.jobs.update {
            $0.count > 0 && context.factories.contains($0.at)
        }
    }
}
extension Pop: Turnable {
    mutating func turn() {
        for i: Int in self.jobs.values.indices {
            self.jobs.values[i].turn()
        }
        self.cash.settle()
        self.equity.turn()
    }
}
extension Pop {
    mutating func egress(
        evaluator: ConditionEvaluator,
        on map: inout GameMap,
        direction: (PopStratum, PopStratum) -> Bool,
    ) {
        let rate: Double = evaluator.output
        if  rate <= 0 {
            return
        }

        let count: Int64 = Binomial[self.today.size, rate].sample(
            using: &map.random.generator
        )
        var targets: [(id: PopType, weight: Int64)] = PopType.allCases.filter {
            direction(self.type.stratum, $0.stratum)
        }.map {
            (id: $0, weight: 1)
        }

        targets.shuffle(using: &map.random.generator)

        guard
        let breakdown: [Int64] = targets.distribute(count, share: \.weight) else {
            return
        }

        for ((target, _), size): ((id: PopType, Int64), Int64) in zip(targets, breakdown)
            where size > 0 {

            if self.type == target {
                // No need to convert to the same type
                continue
            }

            let section: Section = .init(
                culture: self.nat,
                type: target,
                home: self.home
            )

            map.conversions.append(
                .init(from: self.id, size: size, of: self.today.size, to: section)
            )
            // we must deduct this now, because we might have multiple calls to `egress`
            self.today.size -= size
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
        case yesterday_px = "y_px"
        case yesterday_pa = "y_pa"

        case today_size = "t_size"
        case today_mil = "t_mil"
        case today_con = "t_con"
        case today_fl = "t_fl"
        case today_fe = "t_fe"
        case today_fx = "t_fx"
        case today_px = "t_px"
        case today_pa = "t_pa"

        case equity
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
        js[.yesterday_px] = self.yesterday.px
        js[.yesterday_pa] = self.yesterday.pa

        js[.today_size] = self.today.size
        js[.today_mil] = self.today.mil
        js[.today_con] = self.today.con
        js[.today_fl] = self.today.fl
        js[.today_fe] = self.today.fe
        js[.today_fx] = self.today.fx
        js[.today_px] = self.today.px
        js[.today_pa] = self.today.pa

        js[.equity] = self.equity
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
            px: try js[.today_px]?.decode() ?? 1,
            pa: try js[.today_pa]?.decode() ?? 0.5,
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
                px: try js[.yesterday_px]?.decode() ?? today.px,
                pa: try js[.yesterday_pa]?.decode() ?? today.pa,
            ),
            today: today,
            equity: try js[.equity]?.decode() ?? [:],
            jobs: try js[.jobs]?.decode() ?? [:],
        )
    }
}

#if TESTABLE
extension Pop: Equatable, Hashable {}
#endif
