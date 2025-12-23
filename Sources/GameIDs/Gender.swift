import Bijection

/// The number of genders is finite, but at least three.
@frozen public enum Gender: Comparable, CaseIterable {
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
extension Gender: RawRepresentable {
    @Bijection(label: "rawValue") @inlinable public var rawValue: Int8 {
        switch self {
        case .FT: 1
        case .FTS: 2
        case .FC: 3
        case .FCS: 4
        case .XTL: 5
        case .XT: 6
        case .XTG: 7
        case .XCL: 8
        case .XC: 9
        case .XCG: 10
        case .MT: 11
        case .MTS: 12
        case .MC: 13
        case .MCS: 14
        }
    }
}
extension Gender {
    @inlinable public var authority: GenderAuthority { self.group.authority }
    @inlinable public var sex: Sex { self.group.sex }

    @inlinable public var group: GenderGroup {
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
    @inlinable public var transgender: Bool {
        switch self {
        case .FT: true
        case .FTS: true
        case .FC: false
        case .FCS: false

        case .XTL: true
        case .XT: true
        case .XTG: true

        case .XCL: false
        case .XC: false
        case .XCG: false

        case .MT: true
        case .MTS: true
        case .MC: false
        case .MCS: false
        }
    }
}
