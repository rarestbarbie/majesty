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
        self.inventory.profit(variableCosts: 0, fixedCosts: 0)
    }
}
extension Building {
    enum ObjectKey: JSString, Sendable {
        case id
        case tile = "on"
        case type

        case inventory_out = "out"
        case inventory_l = "nl"
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

        js[.inventory_out] = self.inventory.out
        js[.inventory_l] = self.inventory.l
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
            inventory: .init(
                out: try js[.inventory_out]?.decode() ?? .empty,
                l: try js[.inventory_l]?.decode() ?? .empty,
                e: .empty,
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
