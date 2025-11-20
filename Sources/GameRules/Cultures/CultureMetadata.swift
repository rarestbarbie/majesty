import GameEconomy
import GameIDs

public final class CultureMetadata: GameMetadata {
    public typealias ID = CultureType
    public let identity: SymbolAssignment<CultureType>
    public let diet: ResourceTier?
    public let meat: ResourceTier?

    public init(
        identity: SymbolAssignment<CultureType>,
        diet: ResourceTier?,
        meat: ResourceTier?
    ) {
        self.identity = identity
        self.diet = diet
        self.meat = meat
    }
}
extension CultureMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.identity.hash(into: &hasher)
        self.diet?.hash(into: &hasher)
        self.meat?.hash(into: &hasher)

        return hasher.finalize()
    }
}
