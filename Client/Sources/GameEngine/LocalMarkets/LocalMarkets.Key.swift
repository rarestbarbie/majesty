extension LocalMarkets {
    struct Key: Equatable, Hashable {
        let location: Address
        let resource: LocalResource
    }
}
