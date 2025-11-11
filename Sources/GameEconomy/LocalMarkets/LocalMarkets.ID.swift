import GameIDs

extension LocalMarket {
    @frozen public struct ID: Equatable, Hashable {
        public let location: Address
        public let resource: Resource

        @inlinable init(location: Address, resource: Resource) {
            self.location = location
            self.resource = resource
        }
    }
}
extension LocalMarket.ID: CustomStringConvertible {
    @inlinable public var description: String {
        "\(self.location)/\(self.resource)"
    }
}
extension LocalMarket.ID: LosslessStringConvertible {
    @inlinable public init?(_ string: borrowing some StringProtocol) {
        guard
        let slash: String.Index = string.firstIndex(of: "/"),
        let location: Address = .init(string[..<slash]),
        let resource: Resource = .init(string[string.index(after: slash)...]) else {
            return nil
        }

        self.init(location: location, resource: resource)
    }
}
