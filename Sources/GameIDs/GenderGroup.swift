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

    /// This is for UI purposes only, `inherit(recipient:plurality:)` should be used for actual
    /// fiscal transfer calculations, as it models Lesbian Asymmetry.
    @inlinable public var attraction: Sex {
        switch self {
        case .F: .F
        case .FS: .M

        case .XL: .F
        case .X: .X
        case .XG: .M

        case .M: .M
        case .MS: .F
        }
    }

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
