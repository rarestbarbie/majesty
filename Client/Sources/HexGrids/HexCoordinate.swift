@frozen public enum HexCoordinate: Equatable, Hashable, Sendable {
    case n(_ q: Int8, _ r: Int8)
    case e(_ φ: Int8)
    case s(_ q: Int8, _ r: Int8)
}
extension HexCoordinate: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .n(let q, let r): "N\(q),\(r)"
        case .e(let φ): "E\(φ)"
        case .s(let q, let r): "S\(q),\(r)"
        }
    }
}
extension HexCoordinate: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let first: String.Index = string.indices.first else {
            return nil
        }

        let i: String.Index = string.index(after: first)

        switch string[first] {
        case "N":
            if  let coordinate: AxialCoordinate = .init(string[i...]) {
                self = .n(coordinate.q, coordinate.r)
                return
            }
        case "E":
            if  let φ: Int8 = .init(string[i...]) {
                self = .e(φ)
                return
            }
        case "S":
            if  let coordinate: AxialCoordinate = .init(string[i...]) {
                self = .s(coordinate.q, coordinate.r)
                return
            }
        default:
            break
        }

        return nil
    }
}
