import Assert
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
    /// This is part of the persistent state, because it is only computed during a turn, and
    /// we want the budget info to be available for inspection when loading a save.
    var budget: Budget?
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
            budget: nil,
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
        self.budget = nil
        self.equity.turn()
    }
}
extension Factory {
    var profit: ProfitMargins {
        // for Factories, compliance costs scale with number of workers, so all compliance costs
        // are treated as operating costs
        .init(
            materialsCosts: self.inventory.l.valueConsumed + self.spending.wages,
            operatingCosts: self.inventory.e.valueConsumed + self.spending.salariesUsed,
            carryingCosts: self.spending.salariesIdle,
            revenue: self.inventory.out.valueSold
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
        case spending_salariesUsed = "sC"
        case spending_salariesIdle = "sD"
        case spending_wages = "sW"

        case budget_liquidation = "bL"
        case budget_operating = "bO"

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
        js[.spending_salariesUsed] = self.spending.salariesUsed
        js[.spending_salariesIdle] = self.spending.salariesIdle
        js[.spending_wages] = self.spending.wages

        switch self.budget {
        case .constructing(let value)?: js[.budget_operating] = value
        case .liquidating(let value)?: js[.budget_liquidation] = value
        case .active(let value)?: js[.budget_operating] = value
        case nil: break
        }

        js[.y] = self.y
        js[.z] = self.z

        js[.equity] = self.equity
    }
}
extension Factory: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let size: Size = .init(
            level: try js[.size_l]?.decode() ?? 1,
            growthProgress: try js[.size_p]?.decode() ?? 0
        )

        let budget: Budget?

        if  let value: OperatingBudget = try js[.budget_operating]?.decode() {
            budget = size.level == 0 ? .constructing(value) : .active(value)
        } else if
            let value: LiquidationBudget = try js[.budget_liquidation]?.decode() {
            budget = .liquidating(value)
        } else {
            budget = nil
        }

        let today: Dimensions = try js[.z]?.decode() ?? .init()
        self.init(
            id: try js[.id].decode(),
            tile: try js[.tile].decode(),
            type: try js[.type].decode(),
            size: size,
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
                salariesUsed: try js[.spending_salariesUsed]?.decode() ?? 0,
                salariesIdle: try js[.spending_salariesIdle]?.decode() ?? 0,
                wages: try js[.spending_wages]?.decode() ?? 0
            ),
            budget: budget,
            y: try js[.y]?.decode() ?? today,
            z: today,
            equity: try js[.equity]?.decode() ?? [:]
        )
    }
}

#if TESTABLE
extension Factory: Equatable, Hashable {}
#endif
