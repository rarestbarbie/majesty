import GameRules

extension FactoryContext {
    enum EmployeeOperations {
        case hire(FactoryJobOfferBlock, PopType)
        case fire(FactoryJobLayoffBlock)
    }
}
