import GameIDs

extension LocalMarkets {
    @frozen public struct Key: Equatable, Hashable {
        public let location: Address
        public let resource: Resource

        @inlinable init(location: Address, resource: Resource) {
            self.location = location
            self.resource = resource
        }
    }
}
