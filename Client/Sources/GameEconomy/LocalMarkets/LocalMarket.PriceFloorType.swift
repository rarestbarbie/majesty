extension LocalMarket {
    @frozen public enum PriceFloorType {
        case minimumWage
    }
}
extension LocalMarket.PriceFloorType: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .minimumWage: return "Minimum Wage"
        }
    }
}
