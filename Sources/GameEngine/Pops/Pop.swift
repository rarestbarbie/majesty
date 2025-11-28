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

struct Pop: LegalEntityState, Identifiable {
    let id: PopID
    let tile: Address
    let type: PopType
    let nat: String

    var inventory: Inventory
    var spending: Spending
    var budget: Budget?
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
            spending: .zero,
            budget: nil,
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
        self.z.size <= 0
    }
}
extension Pop {
    mutating func prune(in context: GameContext.PruningPass) {
        self.equity.prune(in: context)
        // don’t prune empty jobs yet, they may have interesting deltas
        self.factories.prune(unless: context.factories.contains(_:))
        self.mines.prune(unless: context.mines.contains(_:))
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
        self.spending = .zero
        self.budget = nil
        self.equity.turn()
    }
}
extension Pop {
    mutating func egress(
        evaluator: ConditionEvaluator,
        inherit: Fraction?,
        on turn: inout Turn,
        weight: (PopType) -> Double,
    ) {
        let rate: Double = evaluator.output
        if  rate <= 0 {
            return
        }

        let count: Int64 = Binomial[self.z.size, rate].sample(
            using: &turn.random.generator
        )
        if  count <= 0 {
            return
        }

        /// evaluate this lazily to avoid unnecessary work
        var targets: [(id: PopType, weight: Double)] = PopType.allCases.compactMap {
            let weight: Double = weight($0)
            return weight > 0 ? (id: $0, weight: weight) : nil
        }

        targets.shuffle(using: &turn.random.generator)

        guard
        let breakdown: [Int64] = targets.distribute(count, share: \.weight) else {
            return
        }

        for ((target, _), size): ((id: PopType, Double), Int64) in zip(targets, breakdown)
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

    var profit: ProfitMargins {
        // TODO: this probably needs to be revisited, Slaves should behave like Buildings
        .init(
            materialsCosts: self.inventory.l.valueConsumed,
            operatingCosts: self.inventory.e.valueConsumed,
            carryingCosts: 0,
            revenue: self.inventory.out.valueSold
        )
    }

    var decadence: Double {
        0.1 * self.y.con
    }

    var needsScalePerCapita: (l: Double, e: Double, x: Double) {
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

        case inventory_out = "out"
        case inventory_l = "nl"
        case inventory_e = "ne"
        case inventory_x = "nx"

        case spending_buybacks = "sE"
        case spending_dividend = "sI"

        case budget = "b"

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
        js[.inventory_l] = self.inventory.l
        js[.inventory_e] = self.inventory.e
        js[.inventory_x] = self.inventory.x
        js[.inventory_out] = self.inventory.out
        js[.spending_buybacks] = self.spending.buybacks
        js[.spending_dividend] = self.spending.dividend
        js[.budget] = self.budget

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
                out: try js[.inventory_out]?.decode() ?? .empty,
                l: try js[.inventory_l]?.decode() ?? .empty,
                e: try js[.inventory_e]?.decode() ?? .empty,
                x: try js[.inventory_x]?.decode() ?? .empty
            ),
            spending: .init(
                buybacks: try js[.spending_buybacks]?.decode() ?? 0,
                dividend: try js[.spending_dividend]?.decode() ?? 0,
            ),
            budget: try js[.budget]?.decode(),
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
