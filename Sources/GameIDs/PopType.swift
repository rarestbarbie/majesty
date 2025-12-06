@frozen public struct PopType: Equatable, Hashable, Sendable {
    public let occupation: PopOccupation
    public let gender: Gender
    public let race: CultureID

    @inlinable public init(
        occupation: PopOccupation,
        gender: Gender,
        race: CultureID
    ) {
        self.occupation = occupation
        self.gender = gender
        self.race = race
    }
}
extension PopType {
    @inlinable public var stratum: PopStratum { self.occupation.stratum }

    @inlinable public consuming func with(occupation: PopOccupation) -> Self {
        .init(occupation: occupation, gender: self.gender, race: self.race)
    }
}
