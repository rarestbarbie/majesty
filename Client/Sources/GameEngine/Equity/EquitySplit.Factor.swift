extension EquitySplit {
    enum Factor {
        case reverse(Int64)
        case forward(Int64)
    }
}
extension EquitySplit.Factor {
    var articleIndefinite: String {
        if case .reverse(let factor) = self {
            // We will assume that reverse split factors are less than 1000.
            switch factor {
            case 8, 11, 18, 80 ... 89, 800 ... 899:
                return "an"
            default:
                break
            }
        }

        return "a"
    }
}
extension EquitySplit.Factor: CustomStringConvertible {
    var description: String {
        switch self {
        case .reverse(let factor): "\(factor)-for-1"
        case .forward(let factor): "1-for-\(factor)"
        }
    }
}
