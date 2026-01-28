import GameIDs

enum PopJobType {
    case factory
    case mine
}
extension PopJobType {
    static func r²(yield w: Double, referenceWage w0: Double) -> Double {
        if  w0 <= 0 {
            return PopJobType.r0
        }

        //  x = w / w0
        //  r = 1 / (1 + x)
        //  r = 1 / (1 + w / w0)
        //  r = w0 / (w0 + w)
        //  q = k * r²
        let r: Double = w0 / (w0 + w)
        return r * r
    }

    static var r0: Double { 0.25 }

    func q(yield w: Double, referenceWage w0: Double) -> Double {
        self.q0 * Self.r²(yield: w, referenceWage: w0)
    }

    var q0: Double {
        switch self {
        case .factory: 0.01
        case .mine: 0.02
        }
    }
}
