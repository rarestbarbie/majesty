extension BlocMarket {
    @frozen public struct AssetPair: Hashable {
        public let x: Asset
        public let y: Asset

        @inlinable public init(_ x: Asset, _ y: Asset) {
            self.x = x
            self.y = y
        }
    }
}
extension BlocMarket.AssetPair {
    @inlinable var conjugated: Self {
        .init(self.y, self.x)
    }
}
extension BlocMarket.AssetPair {
    @inlinable public static func code(_ code: some StringProtocol) -> Self? {
        if  let slash: String.Index = code.firstIndex(of: "/"),
            let x: BlocMarket.Asset = .code(code[..<slash]),
            let y: BlocMarket.Asset = .code(code[code.index(after: slash)...]) {
            return .init(x, y)
        } else {
            return nil
        }
    }

    @inlinable public var code: String {
        "\(self.x.code)/\(self.y.code)"
    }
}
