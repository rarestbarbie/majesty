@frozen public enum GenderGroup {
    case F
    case FS

    case XL
    case X
    case XG

    case M
    case MS
}
extension GenderGroup {
    @inlinable public var sex: Sex { self.authority.sex }

    @inlinable public var authority: GenderAuthority {
        switch self {
        case .F: .F
        case .FS: .F

        case .XL: .XL
        case .X: .X
        case .XG: .XG

        case .M: .M
        case .MS: .M
        }
    }
}
extension GenderGroup {
    @inlinable public func inherit(recipient: Self, plurality: Double) -> Double {
        switch self {
        case .F:
            switch recipient {
            case .F: return plurality
            case .FS: return 0

            case .XL: return plurality
            case .X: return plurality
            case .XG: return 0

            case .M: return 0
            case .MS: return 0
            }
        case .FS:
            switch recipient {
            case .F: return 0
            case .FS: return 0

            case .XL: return plurality
            case .X: return plurality
            case .XG: return 0

            case .M: return 0
            case .MS: return 1 - plurality
            }

        case .XL:
            switch recipient {
            case .F: return plurality
            case .FS: return 0

            case .XL: return plurality
            case .X: return plurality
            case .XG: return 0

            case .M: return 0
            case .MS: return 0
            }
        case .X:
            switch recipient {
            case .F: return plurality
            case .FS: return 0

            case .XL: return 0
            case .X: return plurality
            case .XG: return 0

            case .M: return plurality
            case .MS: return 0
            }
        case .XG:
            switch recipient {
            case .F: return 0
            case .FS: return 0

            case .XL: return 0
            case .X: return plurality
            case .XG: return plurality

            case .M: return plurality
            case .MS: return 0
            }

        case .M:
            switch recipient {
            case .F: return 0
            case .FS: return 0

            case .XL: return 0
            case .X: return plurality
            case .XG: return plurality

            case .M: return plurality
            case .MS: return 0
            }
        case .MS:
            switch recipient {
            case .F: return 0
            case .FS: return 1 - plurality

            case .XL: return 0
            case .X: return 0
            case .XG: return 0

            case .M: return 0
            case .MS: return 0
            }
        }
    }
}
