import GameEconomy
import GameState
import GameRules
import JavaScriptKit
import JavaScriptInterop
import VectorCharts

struct PopDetails {
    let id: PopID
    private var state: Pop?
    private var inventory: ResourceInventory
    private var spending: PieChart<CashFlowItem, PieChartLabel>?

    init(id: PopID) {
        self.id = id
        self.inventory = .init()
        self.spending = nil
    }
}
extension PopDetails {
    mutating func update(from snapshot: borrowing GameSnapshot) {
        guard
        let pop: PopContext = snapshot.pops.table[self.id],
        let currency: Fiat = pop.policy?.currency else {
            return
        }

        self.state = pop.state

        self.inventory.reset(
            inputs: pop.state.nl.count + pop.state.ne.count + pop.state.nx.count,
        )

        self.inventory.update(
            from: pop.state.nl,
            tier: .l,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )
        self.inventory.update(
            from: pop.state.ne,
            tier: .e,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )
        self.inventory.update(
            from: pop.state.nx,
            tier: .x,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )

        self.inventory.reset(outputs: pop.state.out.count)
        self.inventory.update(
            from: pop.state.out,
            currency: currency,
            location: pop.state.home,
            snapshot: snapshot
        )

        self.spending = pop.cashFlow.chart(rules: snapshot.rules)
    }
}
extension PopDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id

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

        js[.needs] = self.inventory.needs
        js[.sales] = self.inventory.sales
        js[.spending] = self.spending
    }
}
