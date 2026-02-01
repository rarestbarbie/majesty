import GameIDs

extension GameMetadata.Pops {
    @frozen @usableFromInline struct MetadataFactors {
        @usableFromInline let attributesDefault: PopAttributes
        @usableFromInline let attributesSocial: [SocialSection: PopAttributes]
        @usableFromInline let attributesByRace: [CultureType: PopAttributes]
        @usableFromInline var cultures: [CultureID: Culture]
    }
}
extension GameMetadata.Pops.MetadataFactors {
    @usableFromInline func instantiateMetadata(for type: PopType) -> PopMetadata? {
        guard
        let race: Culture = self.cultures[type.race] else {
            return nil
        }

        var attributes: PopAttributes = self.attributesDefault
        if  let layer: PopAttributes = self.attributesByRace[race.type] {
            attributes |= layer
        }

        let section: GameMetadata.Pops.SocialSection = .init(
            occupation: type.occupation,
            gender: type.gender
        )

        if  let layer: PopAttributes = self.attributesSocial[section] {
            attributes |= layer
        }

        return .init(
            occupation: type.occupation,
            gender: type.gender,
            race: race,
            l: attributes.base.l | attributes.l,
            e: attributes.base.e | attributes.e,
            x: attributes.base.x | attributes.x,
            output: attributes.base.output | attributes.output
        )
    }
}
