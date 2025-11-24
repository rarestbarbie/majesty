import GameRules
import GameState
import GameIDs

struct BuildingContext: LegalEntityContext, RuntimeContext {
    let type: FactoryMetadata
    var state: Building

    private(set) var region: RegionalProperties?
    private(set) var equity: Equity<LEI>.Statistics

    private(set) var cashFlow: CashFlowStatement
    private(set) var budget: FactoryBudget?

    init(type: FactoryMetadata, state: Building) {
        self.type = type
        self.state = state

        self.region = nil
        self.equity = .init()
        self.cashFlow = .init()
        self.budget = nil
    }
}
extension BuildingContext {
    mutating func addPosition(asset: LEI, value: Int64) {
        // TODO
    }
}
