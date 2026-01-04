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

    private var pop: PopSnapshot?

    init(id: PopID, focus: LegalEntityFocus<PopDetailsTab>) {
        self.id = id
        self.open = focus.tab
        self.inventory = .init(focus: focus.needs)
        self.ownership = .init()
        self.pop = nil
    }
}
extension PopDetails: PersistentReportDetails {
    mutating func refocus(on focus: LegalEntityFocus<PopDetailsTab>) {
        self.open = focus.tab
        self.inventory.focus = focus.needs
    }
}
extension PopDetails {
    mutating func update(to pop: PopSnapshot, cache: borrowing GameUI.Cache) {
        switch self.open {
        case .Inventory: self.inventory.update(from: pop, in: cache)
        case .Ownership: self.ownership.update(from: pop, in: cache)
        }

        self.pop = pop
    }
}
extension PopDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open

        case occupation_singular
        case occupation_plural
        case occupation
        case gender
        case cis

        case needs
        case sales
        case spending
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id

        if  let type: PopType = self.pop?.type {
            js[.occupation_singular] = type.occupation.singular
            js[.occupation_plural] = type.occupation.plural
            js[.occupation] = type.occupation
            js[.gender] = type.gender.glyphs
            js[.cis] = type.gender.transgender ? nil : true
        }

        switch self.open {
        case .Inventory: js[.open] = self.inventory
        case .Ownership: js[.open] = self.ownership
        }
    }
}
