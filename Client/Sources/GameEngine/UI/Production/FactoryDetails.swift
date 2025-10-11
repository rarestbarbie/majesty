import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct FactoryDetails {
    let id: FactoryID
    var open: FactoryDetailsTab
    private var inventory: InventoryBreakdown<FactoryDetailsTab>
    private var ownership: OwnershipBreakdown<FactoryDetailsTab>

    private var name: String?

    init(id: FactoryID, open: FactoryDetailsTab) {
        self.id = id
        self.open = open

        self.inventory = .init()
        self.ownership = .init()

        self.name = nil
    }
}
extension FactoryDetails {
    mutating func update(from snapshot: borrowing GameSnapshot) {
        guard
        let factory: FactoryContext = snapshot.factories[self.id] else {
            return
        }

        switch self.open {
        case .Inventory: self.inventory.update(from: factory, in: snapshot)
        case .Ownership: self.ownership.update(from: factory, in: snapshot.context)
        }

        self.name = factory.type.name
    }
}
extension FactoryDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case type
        case open
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.type] = self.name

        switch self.open {
        case .Inventory:    js[.open] = self.inventory
        case .Ownership:    js[.open] = self.ownership
        }
    }
}
