import JavaScriptInterop

@frozen public enum TooltipType: String, ConvertibleToJSValue, LoadableFromJSValue {
    case BuildingAccount
    case BuildingActive
    case BuildingActiveHelp
    case BuildingVacant
    case BuildingVacantHelp
    case BuildingResourceIO
    case BuildingStockpile
    case BuildingExplainPrice
    case BuildingNeeds
    case BuildingOwnershipCountry
    case BuildingOwnershipCulture
    case BuildingOwnershipGender
    case BuildingOwnershipSecurities
    case BuildingCashFlowItem
    case BuildingBudgetItem

    case FactoryAccount
    case FactorySize
    case FactoryResourceIO
    case FactoryStockpile
    case FactoryExplainPrice
    case FactoryClerks
    case FactoryClerksHelp
    case FactoryWorkers
    case FactoryWorkersHelp
    case FactoryNeeds
    case FactoryOwnershipCountry
    case FactoryOwnershipCulture
    case FactoryOwnershipGender
    case FactoryOwnershipSecurities
    case FactorySummarizeEmployees
    case FactoryCashFlowItem
    case FactoryBudgetItem

    case PlanetCell

    case PopAccount
    case PopActive
    case PopActiveHelp
    case PopVacant
    case PopVacantHelp
    case PopJobs
    case PopResourceIO
    case PopResourceOrigin
    case PopStockpile
    case PopExplainPrice
    case PopNeeds
    case PopType
    case PopOwnershipCountry
    case PopOwnershipCulture
    case PopOwnershipGender
    case PopOwnershipSecurities
    case PopCashFlowItem
    case PopBudgetItem

    case MarketLiquidity
    case MarketHistory

    case TileCulture
    case TilePopType
    case TileGDP
    case TileIndustry
    case TileResourceProduced
    case TileResourceConsumed
}
