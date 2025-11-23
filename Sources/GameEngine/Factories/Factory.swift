import JavaScriptKit
import JavaScriptInterop
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import OrderedCollections
import Random

struct Factory: LegalEntityState, Identifiable {
    let id: FactoryID
    let tile: Address
    var type: FactoryType
    var size: Size

    var liquidation: FactoryLiquidation?

    var inventory: Inventory
    var spending: Spending
    var y: Dimensions
    var z: Dimensions

    var equity: Equity<LEI>
}
extension Factory: Sectionable {
    init(id: FactoryID, section: Section) {
        self.init(
            id: id,
            tile: section.tile,
            type: section.type,
            size: .init(level: 0),
            liquidation: nil,
            inventory: .init(),
            spending: .zero,
            y: .init(),
            z: .init(),
            equity: [:],
        )
    }

    var section: Section {
        .init(type: self.type, tile: self.tile)
    }
}
extension Factory: Deletable {
    var dead: Bool {
        if  case _? = self.liquidation,
            self.equity.shares.values.allSatisfy({ $0.shares <= 0 }) {
            true
        } else {
            false
        }
    }
}
extension Factory {
    mutating func prune(in context: GameContext.PruningPass) {
        self.equity.prune(in: context)
    }
}
extension Factory: Turnable {
    mutating func turn() {
        self.spending = .zero
        self.equity.turn()
    }
}
extension Factory {
    var profit: ProfitMargins {
        self.inventory.profit(
            variableCosts: self.spending.wages,
            fixedCosts: self.spending.salaries
        )
    }
}
extension Factory {
    enum ObjectKey: JSString, Sendable {
        case id
        case tile = "on"
        case type
        case size_l
        case size_p
        case liquidation

        case inventory_out = "out"
        case inventory_l = "nl"
        case inventory_e = "ne"
        case inventory_x = "nx"

        case spending_buybacks = "sE"
        case spending_dividend = "sI"
        case spending_salaries = "sC"
        case spending_wages = "sW"

        case y
        case z

        case equity
    }
}
extension Factory: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type.rawValue
        js[.size_l] = self.size.level
        js[.size_p] = self.size.growthProgress
        js[.liquidation] = self.liquidation

        js[.inventory_l] = self.inventory.l
        js[.inventory_e] = self.inventory.e
        js[.inventory_x] = self.inventory.x
        js[.inventory_out] = self.inventory.out

        js[.spending_buybacks] = self.spending.buybacks
        js[.spending_dividend] = self.spending.dividend
        js[.spending_salaries] = self.spending.salaries
        js[.spending_wages] = self.spending.wages

        js[.y] = self.y
        js[.z] = self.z

        js[.equity] = self.equity
    }
}
extension Factory: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = try js[.z]?.decode() ?? .init()
        self.init(
            id: try js[.id].decode(),
            tile: try js[.tile].decode(),
            type: try js[.type].decode(),
            size: .init(
                level: try js[.size_l]?.decode() ?? 1,
                growthProgress: try js[.size_p]?.decode() ?? 0
            ),
            liquidation: try js[.liquidation]?.decode(),
            inventory: .init(
                out: try js[.inventory_out]?.decode() ?? .empty,
                l: try js[.inventory_l]?.decode() ?? .empty,
                e: try js[.inventory_e]?.decode() ?? .empty,
                x: try js[.inventory_x]?.decode() ?? .empty
            ),
            spending: .init(
                buybacks: try js[.spending_buybacks]?.decode() ?? 0,
                dividend: try js[.spending_dividend]?.decode() ?? 0,
                salaries: try js[.spending_salaries]?.decode() ?? 0,
                wages: try js[.spending_wages]?.decode() ?? 0
            ),
            y: try js[.y]?.decode() ?? today,
            z: today,
            equity: try js[.equity]?.decode() ?? [:]
        )
    }
}

#if TESTABLE
extension Factory: Equatable, Hashable {}
#endif
