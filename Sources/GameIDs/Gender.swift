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

    @inlinable public var heterosexual: Bool {
        switch self {
        case .FT: false
        case .FTS: true
        case .FC: false
        case .FCS: true

        case .XTL: false
        case .XT: false
        case .XTG: false

        case .XCL: false
        case .XC: false
        case .XCG: false

        case .MT: false
        case .MTS: true
        case .MC: false
        case .MCS: true
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
extension Gender {
    @inlinable public static func sequestration(
        of population: Sex,
        by authority: GenderAuthority,
        plurality: Double
    ) -> Double {
        switch authority {
        case .F:
            switch population {
            case .F: 0
            case .X: 0
            case .M: 1 - plurality
            }
        case .XL:
            switch population {
            case .F: 1 - plurality
            case .X: 0
            case .M: 0
            }
        case .X:
            switch population {
            case .F: 1 - plurality
            case .X: 0
            case .M: 1 - plurality
            }
        case .XG:
            switch population {
            case .F: 0
            case .X: 0
            case .M: 1 - plurality
            }
        case .M:
            switch population {
            case .F: 1 - plurality
            case .X: 1 - plurality
            case .M: 0
            }
        }
    }

    @inlinable public static func patronage(
        patron: GenderGroup,
        target: GenderGroup,
        plurality: Double
    ) -> Double {
        switch patron {
        case .F:
            switch target {
            case .F: return 1
            case .FS: return 0

            case .XL: return plurality
            case .X: return plurality
            case .XG: return 0

            case .M: return 0
            case .MS: return 0
            }
        case .FS:
            switch target {
            case .F: return 0
            case .FS: return 0

            case .XL: return plurality
            case .X: return plurality
            case .XG: return 0

            case .M: return 0
            case .MS: return 1 - plurality
            }

        case .XL:
            switch target {
            case .F: return 1
            case .FS: return 0

            case .XL: return 1
            case .X: return plurality
            case .XG: return 0

            case .M: return 0
            case .MS: return 0
            }
        case .X:
            switch target {
            case .F: return plurality
            case .FS: return 0

            case .XL: return 0
            case .X: return 1
            case .XG: return 0

            case .M: return plurality
            case .MS: return 0
            }
        case .XG:
            switch target {
            case .F: return 0
            case .FS: return 0

            case .XL: return 0
            case .X: return plurality
            case .XG: return 1

            case .M: return 1
            case .MS: return 0
            }

        case .M:
            switch target {
            case .F: return 0
            case .FS: return 0

            case .XL: return 0
            case .X: return plurality
            case .XG: return plurality

            case .M: return 1
            case .MS: return 0
            }
        case .MS:
            switch target {
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
