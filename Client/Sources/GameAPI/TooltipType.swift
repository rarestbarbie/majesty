import JavaScriptInterop

enum TooltipType: String, LoadableFromJSValue {
    case FactoryAccount
    case FactorySize
    case FactoryDemand
    case FactoryStockpile
    case FactoryOwnershipCountry
    case FactoryOwnershipCulture
    case FactoryWorkers

    case PlanetCell

    case PopAccount
    case PopJobs
    case PopDemand
    case PopStockpile
    case PopNeeds
    case PopType

    case TileCulture
    case TilePopType
}
