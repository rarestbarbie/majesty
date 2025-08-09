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
            let fiat: Int16 = .init(code[code.index(after: code.startIndex)...]) {
            return .fiat(.init(rawValue: fiat))
        } else if
            let good: Int16 = .init(code) {
            return .good(.init(rawValue: good))
        } else {
            return nil
        }
    }

    @inlinable public var code: String {
        switch self {
        case .fiat(let fiat):   "F\(fiat.rawValue)"
        case .good(let good):   "\(good.rawValue)"
        }
    }
}
