import JavaScriptInterop

enum TooltipType: String, LoadableFromJSValue {
    case FactoryAccount
    case FactorySize
    case FactoryDemand
    case FactorySupply
    case FactoryStockpile
    case FactoryExplainPrice
    case FactoryOwnershipCountry
    case FactoryOwnershipCulture
    case FactoryWorkers
    case FactoryStatementItem

    case PlanetCell

    case PopAccount
    case PopJobs
    case PopDemand
    case PopSupply
    case PopStockpile
    case PopExplainPrice
    case PopNeeds
    case PopType
    case PopOwnershipCountry
    case PopOwnershipCulture
    case PopStatementItem

    case MarketLiquidity

    case TileCulture
    case TilePopType
}
