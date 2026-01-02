import GameIDs

struct RegionalAuthority {
    let id: Address
    let governedBy: CountryID
    let occupiedBy: CountryID
    let suzerain: CountryID?
    let country: CountryProperties

    init(
        id: Address,
        governedBy: CountryID,
        occupiedBy: CountryID,
        suzerain: CountryID?,
        country: CountryProperties,
    ) {
        self.id = id
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.suzerain = suzerain
        self.country = country
    }
}
