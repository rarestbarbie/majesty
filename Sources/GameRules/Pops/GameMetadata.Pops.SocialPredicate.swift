import GameIDs

extension GameMetadata.Pops {
    enum SocialPredicate {
        case occupation(in: Set<PopOccupation>)
        case stratum(in: Set<PopStratum>)
        case sex(in: Set<Sex>)

        case heterosexual(Bool)
        case transgender(Bool)
    }
}
extension GameMetadata.Pops.SocialPredicate {
    static func ~= (self: Self, section: GameMetadata.Pops.SocialSection) -> Bool {
        switch self {
        case .occupation(in: let occupations):
            return occupations.contains(section.occupation)
        case .stratum(in: let strata):
            return strata.contains(section.occupation.stratum)
        case .sex(in: let sexes):
            return sexes.contains(section.gender.sex)
        case .heterosexual(let heterosexual):
            return section.gender.heterosexual == heterosexual
        case .transgender(let transgender):
            return section.gender.transgender == transgender
        }
    }
}
