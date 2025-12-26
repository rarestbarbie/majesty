import GameIDs

protocol BuildingProperties: Differentiable<Building.Dimensions> {
    var type: BuildingType { get }
}