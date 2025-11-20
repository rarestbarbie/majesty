import Fraction

extension LocalPrice {
    @frozen public enum TickRate {
        case reduced
        case nominal
        case increased
    }
}
extension LocalPrice.TickRate {
    var divisor: Int64 {
        switch self {
        case .reduced: LocalPrice.cent * 2
        case .nominal: LocalPrice.cent
        case .increased: LocalPrice.cent / 2
        }
    }
}
