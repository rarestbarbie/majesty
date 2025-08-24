import JavaScriptInterop

enum TooltipType: String, LoadableFromJSValue {
    case FactoryAccount
    case FactorySize
    case FactoryDemand
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
    case PopStockpile
    case PopExplainPrice
    case PopNeeds
    case PopType
    case PopStatementItem

    case TileCulture
    case TilePopType
}
