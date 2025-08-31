import Color
import GameEconomy

public final class PopMetadata: Identifiable, Sendable {
    public let singular: String
    public let plural: String
    public let color: Color
    public let l: ResourceTier
    public let e: ResourceTier
    public let x: ResourceTier
    public let output: ResourceTier

    init(
        singular: String,
        plural: String,
        color: Color,
        l: ResourceTier,
        e: ResourceTier,
        x: ResourceTier,
        output: ResourceTier,
    ) {
        self.singular = singular
        self.plural = plural
        self.color = color
        self.l = l
        self.e = e
        self.x = x
        self.output = output
    }
}
extension PopMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.singular.hash(into: &hasher)
        self.plural.hash(into: &hasher)
        self.color.hash(into: &hasher)
        self.l.hash(into: &hasher)
        self.e.hash(into: &hasher)
        self.x.hash(into: &hasher)
        self.output.hash(into: &hasher)

        return hasher.finalize()
    }
}
