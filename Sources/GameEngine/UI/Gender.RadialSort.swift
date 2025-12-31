import GameIDs

extension Gender {
    /// Arranges the gender strata in a radial sort order for pie charts.
    enum RadialSort: Comparable {
        case FCS
        case FTS

        case FC
        case FT

        case XTL
        case XCL

        case XT
        case XC

        case XCG
        case XTG

        case MT
        case MC

        case MTS
        case MCS
    }
}
