import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop
import VectorCharts

struct PopDetails: PersistentReportDetails {
    let id: PopID
    var open: PopDetailsTab

    private var inventory: InventoryBreakdown<PopDetailsTab>
    private var ownership: OwnershipBreakdown<PopDetailsTab>

    private var state: Pop?

    init(id: PopID, open: PopDetailsTab) {
        self.id = id
        self.open = open

        self.inventory = .init()
        self.ownership = .init()
        self.state = nil
    }
}
extension PopDetails {
    mutating func update(to pop: PopContext, from snapshot: borrowing GameSnapshot) {
        self.state = pop.state

        switch self.open {
        case .Inventory: self.inventory.update(from: pop, in: snapshot)
        case .Ownership: self.ownership.update(from: pop, in: snapshot.context)
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

        js[.type_singular] = self.state?.type.singular
        js[.type_plural] = self.state?.type.plural
        js[.type] = self.state?.type

        switch self.open {
        case .Inventory:    js[.open] = self.inventory
        case .Ownership:    js[.open] = self.ownership
        }
    }
}
