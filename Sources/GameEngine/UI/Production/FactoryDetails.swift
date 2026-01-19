import GameEconomy
import GameIDs
import JavaScriptInterop

struct FactoryDetails {
    let id: FactoryID
    private var open: FactoryDetailsTab
    private var inventory: InventoryBreakdown<FactoryDetailsTab>
    private var ownership: OwnershipBreakdown<FactoryDetailsTab>

    private var name: String?

    init(id: FactoryID, focus: LegalEntityFocus<FactoryDetailsTab>) {
        self.id = id
        self.open = focus.tab

        self.inventory = .init(focus: focus.needs)
        self.ownership = .init()

        self.name = nil
    }
}
extension FactoryDetails: PersistentReportDetails {
    mutating func refocus(on focus: LegalEntityFocus<FactoryDetailsTab>) {
        self.open = focus.tab
        self.inventory.focus = focus.needs
    }
}
extension FactoryDetails {
    mutating func update(to factory: FactorySnapshot, cache: borrowing GameUI.Cache) {
        switch self.open {
        case .Inventory: self.inventory.update(from: factory, in: cache)
        case .Ownership: self.ownership.update(from: factory, in: cache)
        }

        self.name = factory.metadata.title
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
