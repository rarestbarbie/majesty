import JavaScriptKit
import JavaScriptInterop
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import OrderedCollections
import Random

struct Building: LegalEntityState, Identifiable {
    let id: BuildingID
    let tile: Address
    var type: BuildingType
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
}
extension Building: Sectionable {
    init(id: BuildingID, section: Section) {
        self.init(
            id: id,
            tile: section.tile,
            type: section.type,
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
        )
    }

    var section: Section {
        .init(type: self.type, tile: self.tile)
    }
}
extension Building: Deletable {
    var dead: Bool {
        // currently, buildings never die
        false
    }
}
extension Building {
    mutating func prune(in context: GameContext.PruningPass) {
        self.equity.prune(in: context)
    }
}
extension Building: Turnable {
    mutating func turn() {
        self.spending = .zero
        self.budget = nil
        self.equity.turn()
    }
}
extension Building {
    var profit: ProfitMargins {
        /// this is the minimum fraction of `fe` we would require if we only paid maintenance
        /// for active facilities
        let expected: Double = Double.init(self.z.active) / Double.init(self.z.total)
        let prorate: Double = max(0, self.z.fe - expected)

        let fixedCosts: Int64 = self.inventory.e.valueConsumed
        /// this is a reasonable underestimate of the amount of maintenance costs that went
        /// towards maintaining vacant facilities
        let carryingCosts: Int64 = Int64.init(Double.init(fixedCosts) * prorate)
        return .init(
            materialsCosts: self.inventory.l.valueConsumed,
            operatingCosts: fixedCosts - carryingCosts,
            carryingCosts: carryingCosts,
            revenue: self.inventory.out.valueSold
        )
    }
}
extension Building {
    enum ObjectKey: JSString, Sendable {
        case id
        case tile = "on"
        case type
        case mothballed
        case destroyed
        case restored
        case created

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
    }
}
extension Building: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.tile] = self.tile
        js[.type] = self.type
        js[.mothballed] = self.mothballed
        js[.destroyed] = self.destroyed
        js[.restored] = self.restored
        js[.created] = self.created

        js[.inventory_out] = self.inventory.out
        js[.inventory_l] = self.inventory.l
        js[.inventory_e] = self.inventory.e
        js[.inventory_x] = self.inventory.x

        js[.spending_buybacks] = self.spending.buybacks
        js[.spending_dividend] = self.spending.dividend

        js[.budget] = self.budget

        js[.y] = self.y
        js[.z] = self.z

        js[.equity] = self.equity
    }
}
extension Building: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let today: Dimensions = try js[.z]?.decode() ?? .init()
        self.init(
            id: try js[.id].decode(),
            tile: try js[.tile].decode(),
            type: try js[.type].decode(),
            mothballed: try js[.mothballed]?.decode() ?? 0,
            destroyed: try js[.destroyed]?.decode() ?? 0,
            restored: try js[.restored]?.decode() ?? 0,
            created: try js[.created]?.decode() ?? 0,
            inventory: .init(
                out: try js[.inventory_out]?.decode() ?? .empty,
                l: try js[.inventory_l]?.decode() ?? .empty,
                e: try js[.inventory_e]?.decode() ?? .empty,
                x: try js[.inventory_x]?.decode() ?? .empty,
            ),
            spending: .init(
                buybacks: try js[.spending_buybacks]?.decode() ?? 0,
                dividend: try js[.spending_dividend]?.decode() ?? 0,
            ),
            budget: try js[.budget]?.decode(),
            y: try js[.y]?.decode() ?? today,
            z: today,
            equity: try js[.equity]?.decode() ?? [:]
        )
    }
}
