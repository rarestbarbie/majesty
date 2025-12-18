import GameEconomy
import GameIDs
import GameState
import JavaScriptKit
import JavaScriptInterop
import VectorCharts

struct PopDetails {
    let id: PopID
    private var open: PopDetailsTab
    private var inventory: InventoryBreakdown<PopDetailsTab>
    private var ownership: OwnershipBreakdown<PopDetailsTab>

    private var state: Pop?

    init(id: PopID, focus: InventoryBreakdown<PopDetailsTab>.Focus) {
        self.id = id
        self.open = focus.tab
        self.inventory = .init(focus: focus.needs)
        self.ownership = .init()
        self.state = nil
    }
}
extension PopDetails: PersistentReportDetails {
    mutating func refocus(on focus: InventoryBreakdown<PopDetailsTab>.Focus) {
        self.open = focus.tab
        self.inventory.focus = focus.needs
    }
}
extension PopDetails {
    mutating func update(to pop: PopContext, from snapshot: borrowing GameSnapshot, mines: DynamicContextTable<MineContext>) {
        self.state = pop.state

        switch self.open {
        case .Inventory: self.inventory.update(from: pop, in: snapshot, mines: mines)
        case .Ownership: self.ownership.update(from: pop, in: snapshot)
        }
    }
}
extension PopDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open

        case type_singular
        case type_plural
        case type

        case needs
        case sales
        case spending
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id

        js[.type_singular] = self.state?.occupation.singular
        js[.type_plural] = self.state?.occupation.plural
        js[.type] = self.state?.type.occupation

        switch self.open {
        case .Inventory: js[.open] = self.inventory
        case .Ownership: js[.open] = self.ownership
        }
    }
}
