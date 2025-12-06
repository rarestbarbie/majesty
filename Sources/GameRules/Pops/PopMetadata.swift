import Color
import GameIDs
import GameEconomy
import OrderedCollections

public final class PopMetadata: Sendable {
    public let occupation: PopOccupation
    public let gender: Gender
    public let race: Culture

    public let l: ResourceTier
    public let e: ResourceTier
    public let x: ResourceTier
    public let output: ResourceTier

    public init(
        occupation: PopOccupation,
        gender: Gender,
        race: Culture,
        l: ResourceTier,
        e: ResourceTier,
        x: ResourceTier,
        output: ResourceTier
    ) {
        self.occupation = occupation
        self.gender = gender
        self.race = race
        self.l = l
        self.e = e
        self.x = x
        self.output = output
    }
}
extension PopMetadata: Identifiable {
    @inlinable public var id: PopType {
        .init(
            occupation: self.occupation,
            gender: self.gender,
            race: self.race.id
        )
    }
}
