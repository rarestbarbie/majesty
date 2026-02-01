import GameIDs

extension GameMetadata.Pops {
    @frozen @usableFromInline struct SocialSection: Hashable {
        let occupation: PopOccupation
        let gender: Gender
    }
}
extension GameMetadata.Pops.SocialSection {
    static var matrix: [Self] {
        var cases: [Self] = []
        ;   cases.reserveCapacity(PopOccupation.allCases.count * Gender.allCases.count)
        for occupation: PopOccupation in PopOccupation.allCases {
            for gender: Gender in Gender.allCases {
                cases.append(.init(occupation: occupation, gender: gender))
            }
        }
        return cases
    }
}
