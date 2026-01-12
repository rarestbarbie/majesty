import JavaScriptKit

extension GameMetadata {
    @frozen public enum Namespace: JSString {
        case legend
        case pops

        case buildings
        case building_costs
        case factories
        case factory_costs
        case resources
        case mines
        case technologies

        case biology
        case geology
        case terrains

        case settings
    }
}
