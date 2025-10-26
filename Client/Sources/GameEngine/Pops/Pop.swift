import Assert
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import Random
import OrderedCollections

struct Pop: LegalEntityState, IdentityReplaceable {
    var id: PopID
    let tile: Address
    let type: PopType
    let nat: String

    var inventory: Inventory
    var yesterday: Dimensions
    var today: Dimensions

    var equity: Equity<LEI>

    var factories: OrderedDictionary<FactoryID, FactoryJob>
    var mines: OrderedDictionary<MineID, MiningJob>
}
extension Pop: Sectionable {
    init(id: PopID, section: Section) {
        self.init(
            id: id,
            tile: section.tile,
            type: section.type,
            nat: section.culture,
            inventory: .init(),
            yesterday: .init(),
            today: .init(),
            equity: [:],
            factories: [:],
            mines: [:]
        )
    }

    var section: Section {
        .init(culture: self.nat, type: self.type, tile: self.tile)
    }
}
extension Pop: Deletable {
    var dead: Bool {
        if  self.today.size == 0,
            self.inventory.account.balance == 0,
            self.equity.shares.values.allSatisfy({ $0.shares <= 0 }) {
            true
        } else {
            false
        }
    }
}
extension Pop {
    mutating func prune(in context: GameContext.PruningPass) {
        self.equity.prune(in: context)
        // don’t prune empty jobs yet, they may have interesting deltas
        self.factories.update { context.factories.contains($0.id) }
        self.mines.update { context.mines.contains($0.id) }
    }
}
extension Pop: Turnable {
    mutating func turn() {
        self.factories.update {
            $0.turn()
            return $0.count > 0
        }
        self.mines.update {
            $0.turn()
            return $0.count > 0
        }
        self.inventory.account.settle()
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
                tile: self.tile
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
        self.today.size
            - self.factories.values.reduce(0) { $0 + $1.count }
            - self.mines.values.reduce(0) { $0 + $1.count }
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
        case tile = "on"
        case type
        case nat

        case inventory_account = "cash"
        case inventory_out = "out"
        case inventory_l = "nl"
        case inventory_e = "ne"
        case inventory_x = "nx"

        case yesterday_size = "y_size"
        case yesterday_mil = "y_mil"
        case yesterday_con = "y_con"
        case yesterday_fl = "y_fl"
        case yesterday_fe = "y_fe"
        case yesterday_fx = "y_fx"
        case yesterday_px = "y_px"
        case yesterday_pa = "y_pa"
        case yesterday_vi = "y_vi"

        case today_size = "t_size"
        case today_mil = "t_mil"
        case today_con = "t_con"
        case today_fl = "t_fl"
        case today_fe = "t_fe"
        case today_fx = "t_fx"
        case today_px = "t_px"
        case today_pa = "t_pa"
        case today_vi = "t_vi"

        case equity
        case factories
        case mines
    }
}
extension Pop: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type
        js[.nat] = self.nat
        js[.inventory_account] = self.inventory.account
        js[.inventory_l] = self.inventory.l
        js[.inventory_e] = self.inventory.e
        js[.inventory_x] = self.inventory.x
        js[.inventory_out] = self.inventory.out

        js[.yesterday_size] = self.yesterday.size
        js[.yesterday_mil] = self.yesterday.mil
        js[.yesterday_con] = self.yesterday.con
        js[.yesterday_fl] = self.yesterday.fl
        js[.yesterday_fe] = self.yesterday.fe
        js[.yesterday_fx] = self.yesterday.fx
        js[.yesterday_px] = self.yesterday.px
        js[.yesterday_pa] = self.yesterday.pa
        js[.yesterday_vi] = self.yesterday.vi

        js[.today_size] = self.today.size
        js[.today_mil] = self.today.mil
        js[.today_con] = self.today.con
        js[.today_fl] = self.today.fl
        js[.today_fe] = self.today.fe
        js[.today_fx] = self.today.fx
        js[.today_px] = self.today.px
        js[.today_pa] = self.today.pa
        js[.today_vi] = self.today.vi

        js[.equity] = self.equity
        js[.factories] = self.factories.isEmpty ? nil : self.factories
        js[.mines] = self.mines.isEmpty ? nil : self.mines
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
            vi: try js[.today_vi]?.decode() ?? 0
        )
        self.init(
            id: try js[.id]?.decode() ?? 0,
            tile: try js[.tile].decode(),
            type: try js[.type].decode(),
            nat: try js[.nat].decode(),
            inventory: .init(
                account: try js[.inventory_account]?.decode() ?? .init(),
                out: try js[.inventory_out]?.decode() ?? .init(),
                l: try js[.inventory_l]?.decode() ?? .init(),
                e: try js[.inventory_e]?.decode() ?? .init(),
                x: try js[.inventory_x]?.decode() ?? .init()
            ),
            yesterday: .init(
                size: try js[.yesterday_size]?.decode() ?? today.size,
                mil: try js[.yesterday_mil]?.decode() ?? today.mil,
                con: try js[.yesterday_con]?.decode() ?? today.con,
                fl: try js[.yesterday_fl]?.decode() ?? today.fl,
                fe: try js[.yesterday_fe]?.decode() ?? today.fe,
                fx: try js[.yesterday_fx]?.decode() ?? today.fx,
                px: try js[.yesterday_px]?.decode() ?? today.px,
                pa: try js[.yesterday_pa]?.decode() ?? today.pa,
                vi: try js[.yesterday_vi]?.decode() ?? today.vi,
            ),
            today: today,
            equity: try js[.equity]?.decode() ?? [:],
            factories: try js[.factories]?.decode() ?? [:],
            mines: try js[.mines]?.decode() ?? [:]
        )
    }
}

#if TESTABLE
extension Pop: Equatable, Hashable {}
#endif
