import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct BuildingDetails {
    let id: BuildingID
    private var open: BuildingDetailsTab
    private var inventory: InventoryBreakdown<BuildingDetailsTab>
    private var ownership: OwnershipBreakdown<BuildingDetailsTab>

    private var name: String?

    init(id: BuildingID, focus: InventoryBreakdown<BuildingDetailsTab>.Focus) {
        self.id = id
        self.open = focus.tab

        self.inventory = .init(focus: focus.needs)
        self.ownership = .init()

        self.name = nil
    }
}
extension BuildingDetails: PersistentReportDetails {
    mutating func refocus(on focus: InventoryBreakdown<BuildingDetailsTab>.Focus) {
        self.open = focus.tab
        self.inventory.focus = focus.needs
    }
}
extension BuildingDetails {
    mutating func update(to building: BuildingSnapshot, cache: borrowing GameUI.Cache) {
        switch self.open {
        case .Inventory: self.inventory.update(from: building, in: cache)
        case .Ownership: self.ownership.update(from: building, in: cache)
        }

        self.name = building.metadata.title
    }
}
extension BuildingDetails: JavaScriptEncodable {
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
