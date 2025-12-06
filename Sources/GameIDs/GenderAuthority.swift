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
extension GenderAuthority {
    @inlinable public func sequestration(recipient: Sex, plurality: Double) -> Double {
        switch self {
        case .F:
            switch recipient {
            case .F: 0
            case .X: 0
            case .M: 1 - plurality
            }
        case .XL:
            switch recipient {
            case .F: 1 - plurality
            case .X: 0
            case .M: 0
            }
        case .X:
            switch recipient {
            case .F: 1 - plurality
            case .X: 0
            case .M: 1 - plurality
            }
        case .XG:
            switch recipient {
            case .F: 0
            case .X: 0
            case .M: 1 - plurality
            }
        case .M:
            switch recipient {
            case .F: 1 - plurality
            case .X: 1 - plurality
            case .M: 0
            }
        }
    }
}
