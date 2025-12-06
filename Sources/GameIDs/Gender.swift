import Bijection

/// The number of genders is at least three, but finite.
@frozen public enum Gender: Int8, CaseIterable {
    case FT
    case FTS
    case FC
    case FCS

    case XTL
    case XT
    case XTG

    case XCL
    case XC
    case XCG

    case MT
    case MTS
    case MC
    case MCS
}
extension Gender {
    var authority: GenderAuthority { self.group.authority }
    var sex: Sex { self.group.sex }

    var group: GenderGroup {
        switch self {
        case .FT: .F
        case .FTS: .FS
        case .FC: .F
        case .FCS: .FS

        case .XTL: .XL
        case .XT: .X
        case .XTG: .XG

        case .XCL: .XL
        case .XC: .X
        case .XCG: .XG

        case .MT: .M
        case .MTS: .MS
        case .MC: .M
        case .MCS: .MS
        }
    }
}
