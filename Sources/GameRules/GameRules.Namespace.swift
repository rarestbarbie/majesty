import JavaScriptKit

extension GameRules {
    @frozen public enum Namespace: JSString {
        case buildings
        case building_costs
        case factories
        case factory_costs
        case resources
        case mines
        case pops
        case technologies

        case biology
        case geology
        case terrains

        case exchange
    }
}
