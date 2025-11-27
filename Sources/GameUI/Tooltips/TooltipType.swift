import JavaScriptInterop
import JavaScriptKit

@frozen public enum TooltipType: String, ConvertibleToJSValue, LoadableFromJSValue {
    case BuildingAccount
    case BuildingActive
    case BuildingVacant
    case BuildingResourceIO
    case BuildingStockpile
    case BuildingExplainPrice
    case BuildingNeeds
    case BuildingOwnershipCountry
    case BuildingOwnershipCulture
    case BuildingOwnershipSecurities
    case BuildingCashFlowItem
    case BuildingBudgetItem

    case FactoryAccount
    case FactorySize
    case FactoryResourceIO
    case FactoryStockpile
    case FactoryExplainPrice
    case FactoryClerks
    case FactoryWorkers
    case FactoryNeeds
    case FactoryOwnershipCountry
    case FactoryOwnershipCulture
    case FactoryOwnershipSecurities
    case FactorySummarizeEmployees
    case FactoryCashFlowItem
    case FactoryBudgetItem

    case PlanetCell

    case PopAccount
    case PopJobs
    case PopResourceIO
    case PopResourceOrigin
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
