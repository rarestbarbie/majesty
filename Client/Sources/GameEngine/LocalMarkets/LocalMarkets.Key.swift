import GameIDs

extension LocalMarkets {
    struct Key: Equatable, Hashable {
        let location: Address
        let resource: Resource
    }
}
