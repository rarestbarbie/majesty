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
    var size: Int64

    var inventory: Inventory
    var spending: Spending
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
            size: 0,
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
        self.equity.turn()
    }
}
extension Building {
    var profit: ProfitMargins {
        self.inventory.profit(variableCosts: 0, fixedCosts: 0)
    }
}
