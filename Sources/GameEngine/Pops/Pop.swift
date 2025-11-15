import Assert
import Fraction
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
    var y: Dimensions
    var z: Dimensions

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
            y: .init(),
            z: .init(),
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
        guard self.z.size <= 0 else {
            return false
        }

        #assert(
            self.inventory.account.balance == 0,
            "Pop (id = \(self.id)) is dead but still has assets!!!"
        )

        return true
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
        targets: [(id: PopType, weight: Int64)],
        inherit: Fraction?,
        on turn: inout Turn,
    ) {
        let rate: Double = evaluator.output
        if  rate <= 0 {
            return
        }

        let count: Int64 = Binomial[self.z.size, rate].sample(
            using: &turn.random.generator
        )

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

            let inherits: Fraction
            if  size < self.z.size {
                let fraction: Fraction = size %/ self.z.size
                inherits = inherit.map { $0 * fraction } ?? fraction
            } else {
                inherits = 1
            }

            turn.conversions.append(
                .init(from: self.id, size: size, to: section, inherits: inherits)
            )
            // we must deduct this now, because we might have multiple calls to `egress`
            self.z.size -= size
        }

        #assert(
            self.z.size >= 0,
            "Pop (id = \(self.id)) has negative size (\(self.z.size))!"
        )
    }
}
extension Pop {
    func employed() -> Int64 {
        self.factories.values.reduce(0) { $0 + $1.count } +
        self.mines.values.reduce(0) { $0 + $1.count }
    }

    var decadence: Double {
        0.1 * self.y.con
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

        case y
        case z

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

        js[.y] = self.y
        js[.z] = self.z

        js[.equity] = self.equity
        js[.factories] = self.factories.isEmpty ? nil : self.factories
        js[.mines] = self.mines.isEmpty ? nil : self.mines
    }
}
extension Pop: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = try js[.z]?.decode() ?? .init()
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
            y: try js[.y]?.decode() ?? today,
            z: today,
            equity: try js[.equity]?.decode() ?? [:],
            factories: try js[.factories]?.decode() ?? [:],
            mines: try js[.mines]?.decode() ?? [:]
        )
    }
}

#if TESTABLE
extension Pop: Equatable, Hashable {}
#endif
