import JavaScriptInterop

enum TooltipType: String, LoadableFromJSValue {
    case FactoryAccount
    case FactorySize
    case FactoryResourceIO
    case FactoryStockpile
    case FactoryExplainPrice
    case FactoryOwnershipCountry
    case FactoryOwnershipCulture
    case FactoryOwnershipSecurities
    case FactoryWorkers
    case FactoryCashFlowItem
    case FactoryBudgetItem

    case PlanetCell

    case PopAccount
    case PopJobs
    case PopResourceIO
    case PopStockpile
    case PopExplainPrice
    case PopNeeds
    case PopType
    case PopOwnershipCountry
    case PopOwnershipCulture
    case PopOwnershipSecurities
    case PopCashFlowItem
    case PopBudgetItem

    case MarketLiquidity

    case TileCulture
    case TilePopType
}
