import GameIDs

protocol FactoryProperties: Differentiable<Factory.Dimensions> {
    var type: FactoryType { get }
}
