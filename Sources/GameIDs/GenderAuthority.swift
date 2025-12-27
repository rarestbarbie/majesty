@frozen public enum GenderAuthority: Int8 {
    case F

    case XL
    case X
    case XG

    case M
}
extension GenderAuthority {
    @inlinable public var sex: Sex {
        switch self {
        case .F: .F
        case .XL: .X
        case .X: .X
        case .XG: .X
        case .M: .M
        }
    }
}
