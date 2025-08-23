import GameEconomy
import GameState
import JavaScriptKit
import JavaScriptInterop

struct FactoryDetails {
    let id: FactoryID
    var open: FactoryDetailsTab
    var inventory: FactoryInventory
    var ownership: FactoryOwnership

    init(id: FactoryID, open: FactoryDetailsTab) {
        self.id = id
        self.open = open

        self.inventory = .init()
        self.ownership = .init()
    }
}
extension FactoryDetails {
    mutating func update(in context: GameContext) {
        guard
        let factory: FactoryContext = context.factories[self.id]
        else {
            return
        }

        switch self.open {
        case .Inventory: self.inventory.update(from: factory, in: context)
        case .Ownership: self.ownership.update(from: factory, in: context)
        }
    }
}
extension FactoryDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id

        switch self.open {
        case .Inventory:    js[.open] = self.inventory
        case .Ownership:    js[.open] = self.ownership
        }
    }
}
