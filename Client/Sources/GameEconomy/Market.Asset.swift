import GameIDs

/// Conventionally, we order the assets in a ``Market.Pair`` in ascending order, and we
/// want fiat currencies to appear on the right side of the pair, for pairs that contain one
/// fiat currency and one good. Thus, we order ``fiat(_:)`` after ``good(_:)``.
extension Market {
    @frozen public enum Asset: Equatable, Hashable, Comparable, Sendable {
        case good(Resource)
        case fiat(Fiat)
    }
}
extension Market.Asset {
    @inlinable public static func code(_ code: some StringProtocol) -> Self? {
        if case "F"? = code.first,
            let fiat: Fiat = .init(code[code.index(after: code.startIndex)...]) {
            return .fiat(fiat)
        } else if
            let good: Resource = .init(code) {
            return .good(good)
        } else {
            return nil
        }
    }

    @inlinable public var code: String {
        switch self {
        case .fiat(let fiat):   "F\(fiat)"
        case .good(let good):   "\(good)"
        }
    }
}
