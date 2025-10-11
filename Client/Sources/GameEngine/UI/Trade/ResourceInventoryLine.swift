import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct ResourceInventoryLine: Equatable, Hashable {
    @usableFromInline let type: Resource
    @usableFromInline let tier: ResourceTierIdentifier

    @inlinable init(type: Resource, tier: ResourceTierIdentifier) {
        self.type = type
        self.tier = tier
    }
}
extension ResourceInventoryLine: ConvertibleToJSString, LoadableFromJSString {}
extension ResourceInventoryLine: CustomStringConvertible {
    @inlinable public var description: String { "\(self.tier)\(self.type)" }
}
extension ResourceInventoryLine: LosslessStringConvertible {
    @inlinable public init?(_ string: borrowing some StringProtocol) {
        guard
        let first: String.Index = string.unicodeScalars.indices.first,
        let type: Resource = .init(string[string.unicodeScalars.index(after: first)...]),
        let tier: ResourceTierIdentifier = .init(rawValue: string.unicodeScalars[first]) else {
            return nil
        }

        self.init(type: type, tier: tier)
    }
}
