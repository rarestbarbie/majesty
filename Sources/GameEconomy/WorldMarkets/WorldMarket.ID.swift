extension WorldMarket {
    @frozen public struct ID: Hashable {
        public let x: Asset
        public let y: Asset

        @inlinable public init(_ x: Asset, _ y: Asset) {
            self.x = x
            self.y = y
        }
    }
}
extension WorldMarket.ID {
    @inlinable var conjugated: Self {
        .init(self.y, self.x)
    }
}
extension WorldMarket.ID: CustomStringConvertible {
    @inlinable public var description: String {
        "\(self.x)/\(self.y)"
    }
}
extension WorldMarket.ID: LosslessStringConvertible {
    @inlinable public init?(_ code: borrowing some StringProtocol) {
        if  let slash: String.Index = code.firstIndex(of: "/"),
            let x: WorldMarket.Asset = .init(code[..<slash]),
            let y: WorldMarket.Asset = .init(code[code.index(after: slash)...]) {
            self.init(x, y)
        } else {
            return nil
        }
    }
}
