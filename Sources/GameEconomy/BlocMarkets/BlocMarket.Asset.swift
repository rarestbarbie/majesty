import GameIDs

/// Conventionally, we order the assets in a ``Market.Pair`` in ascending order, and we
/// want fiat currencies to appear on the right side of the pair, for pairs that contain one
/// fiat currency and one good. Thus, we order ``fiat(_:)`` after ``good(_:)``.
extension BlocMarket {
    @frozen public enum Asset: Equatable, Hashable, Comparable, Sendable {
        case good(Resource)
        case fiat(CurrencyID)
    }
}
extension BlocMarket.Asset: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .fiat(let fiat):   "F\(fiat)"
        case .good(let good):   "\(good)"
        }
    }
}
extension BlocMarket.Asset: LosslessStringConvertible {
    @inlinable public init?(_ code: borrowing some StringProtocol) {
        if case "F"? = code.first,
            let fiat: CurrencyID = .init(code[code.index(after: code.startIndex)...]) {
            self = .fiat(fiat)
        } else if
            let good: Resource = .init(code) {
            self = .good(good)
        } else {
            return nil
        }
    }
}
