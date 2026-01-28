import Assert
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import JavaScriptInterop
import Random
import OrderedCollections

struct Pop: PopProperties, LegalEntityState, Identifiable {
    let id: PopID
    let type: PopType
    let tile: Address

    var mothballed: Int64
    var destroyed: Int64
    var restored: Int64
    var created: Int64

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
            type: section.type,
            tile: section.tile,
            mothballed: 0,
            destroyed: 0,
            restored: 0,
            created: 0,
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

    var section: Section { .init(type: self.type, tile: self.tile) }
}
extension Pop: Deletable {
    var dead: Bool {
        self.z.total <= 0
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

        self.mothballed = 0
        self.destroyed = 0
        self.restored = 0
        self.created = 0

        self.spending = .zero
        self.budget = nil
        self.equity.turn()
    }
}
extension Pop {
    func employedOverCapacity() -> Int64 {
        self.employed() - self.z.active
    }
    func employed() -> Int64 {
        self.factories.values.reduce(0) { $0 + $1.count } +
        self.mines.values.reduce(0) { $0 + $1.count }
    }

    mutating func egress(
        evaluator: ConditionEvaluator,
        inherit: Fraction?,
        on turn: inout Turn,
        weight: (PopOccupation) -> Double,
    ) {
        let rate: Double = evaluator.output
        if  rate <= 0 {
            return
        }

        let count: Int64 = Binomial[self.z.active, rate].sample(
            using: &turn.random.generator
        )
        if  count <= 0 {
            return
        }

        /// evaluate this lazily to avoid unnecessary work
        var targets: [(id: PopOccupation, weight: Double)] = PopOccupation.allCases.compactMap {
            let weight: Double = weight($0)
            return weight > 0 ? (id: $0, weight: weight) : nil
        }

        targets.shuffle(using: &turn.random.generator)

        guard
        let breakdown: [Int64] = targets.distribute(count, share: \.weight) else {
            return
        }

        for ((target, _), size): ((id: PopOccupation, Double), Int64) in zip(targets, breakdown)
            where size > 0 {

            if self.type.occupation == target {
                // No need to convert to the same type
                continue
            }

            let section: Section = .init(
                type: self.type.with(occupation: target),
                tile: self.tile
            )
            let inherits: Fraction
            if  size < self.z.active {
                let fraction: Fraction = size %/ self.z.active
                inherits = inherit.map { $0 * fraction } ?? fraction
            } else {
                inherits = 1
            }

            turn.conversions.append(
                .init(from: self.id, size: size, to: section, inherits: inherits)
            )
            // we must deduct this now, because we might have multiple calls to `egress`
            self.z.active -= size
        }

        #assert(
            self.z.active >= 0,
            "Pop (id = \(self.id)) has negative size (\(self.z.active))!"
        )
    }
}
extension Pop {
    enum ObjectKey: JSString, Sendable {
        case id
        case type_occupation = "J"
        case type_gender = "G"
        case type_race = "R"
        case tile = "on"

        case mothballed = "dm"
        case destroyed = "dd"
        case restored = "dr"
        case created = "dc"

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
        js[.type_occupation] = self.type.occupation
        js[.type_gender] = self.type.gender
        js[.type_race] = self.type.race
        js[.tile] = self.tile
        js[.mothballed] = self.mothballed == 0 ? nil : self.mothballed
        js[.destroyed] = self.destroyed == 0 ? nil : self.destroyed
        js[.restored] = self.restored == 0 ? nil : self.restored
        js[.created] = self.created == 0 ? nil : self.created
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
            type: .init(
                occupation: try js[.type_occupation].decode(),
                gender: try js[.type_gender].decode(),
                race: try js[.type_race].decode()
            ),
            tile: try js[.tile].decode(),
            mothballed: try js[.mothballed]?.decode() ?? 0,
            destroyed: try js[.destroyed]?.decode() ?? 0,
            restored: try js[.restored]?.decode() ?? 0,
            created: try js[.created]?.decode() ?? 0,
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
extension Pop: Equatable {}
#endif
