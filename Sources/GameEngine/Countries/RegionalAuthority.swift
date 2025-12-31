import GameIDs

struct RegionalAuthority {
    let governedBy: CountryID
    let occupiedBy: CountryID
    let suzerain: CountryID?
    let country: CountryProperties

    init(
        governedBy: CountryID,
        occupiedBy: CountryID,
        suzerain: CountryID?,
        country: CountryProperties,
    ) {
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.suzerain = suzerain
        self.country = country
    }
}
