@frozen public struct MineVein: Equatable, Hashable {
    public let mine: MineID
    public let resource: Resource

    @inlinable public init(mine: MineID, resource: Resource) {
        self.mine = mine
        self.resource = resource
    }
}
extension MineVein: CustomStringConvertible {
    @inlinable public var description: String {
        "\(self.mine)/\(self.resource)"
    }
}
extension MineVein: LosslessStringConvertible {
    @inlinable public init?(_ string: borrowing some StringProtocol) {
        guard
        let slash: String.Index = string.firstIndex(of: "/"),
        let mine: MineID = .init(string[..<slash]),
        let vein: Resource = .init(string[string.index(after: slash)...]) else {
            return nil
        }

        self.init(mine: mine, resource: vein)
    }
}
