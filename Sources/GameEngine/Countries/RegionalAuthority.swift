import GameIDs

@dynamicMemberLookup struct RegionalAuthority {
    let id: Address
    let country: DiplomaticAuthority

    init(id: Address, country: DiplomaticAuthority) {
        self.id = id
        self.country = country
    }
}
extension RegionalAuthority {
    subscript<T>(dynamicMember keyPath: KeyPath<DiplomaticAuthority, T>) -> T {
        self.country[keyPath: keyPath]
    }
}
